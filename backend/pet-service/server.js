const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');
const winston = require('winston');
const redis = require('redis');
const { promisify } = require('util');

// Configure logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  defaultMeta: { service: 'pet-service' },
  transports: [
    new winston.transports.Console({
      format: winston.format.simple(),
    }),
  ],
});

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Request logging middleware
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    logger.info({
      method: req.method,
      path: req.path,
      statusCode: res.statusCode,
      duration: `${duration}ms`,
    });
  });
  next();
});

// Configure AWS with connection pooling
AWS.config.update({
  region: process.env.AWS_REGION || 'us-west-2',
  maxRetries: 3,
  retryDelayOptions: {
    customBackoff: function(retryCount) {
      return Math.pow(2, retryCount) * 100;
    }
  }
});

const dynamoDB = new AWS.DynamoDB.DocumentClient({
  region: process.env.AWS_REGION || 'us-west-2',
  httpOptions: {
    connectTimeout: 1000,
    timeout: 5000,
    agent: new AWS.NodeHttpClient.HttpsAgent({
      keepAlive: true,
      maxSockets: 50,
      rejectUnauthorized: true
    })
  }
});
const tableName = process.env.DYNAMODB_TABLE || 'pet-hospital-pets';

// Configure Redis client with error handling
let redisClient = null;
const CACHE_TTL = 300; // 5 minutes
const REDIS_HOST = process.env.REDIS_HOST || 'localhost';
const REDIS_PORT = process.env.REDIS_PORT || 6379;

async function initializeRedis() {
  try {
    redisClient = redis.createClient({
      host: REDIS_HOST,
      port: REDIS_PORT,
      retry_strategy: (options) => {
        if (options.error && options.error.code === 'ECONNREFUSED') {
          logger.warn('Redis connection refused, continuing without cache');
          return undefined; // Don't retry
        }
        if (options.total_retry_time > 1000 * 60 * 60) {
          logger.error('Redis retry time exhausted');
          return new Error('Retry time exhausted');
        }
        if (options.attempt > 3) {
          logger.warn('Max Redis retry attempts reached, continuing without cache');
          return undefined;
        }
        return Math.min(options.attempt * 100, 3000);
      }
    });

    redisClient.on('error', (err) => {
      logger.warn('Redis client error:', err.message);
      redisClient = null; // Disable caching on error
    });

    redisClient.on('connect', () => {
      logger.info('Connected to Redis cache');
    });

    redisClient.on('end', () => {
      logger.warn('Redis connection ended, continuing without cache');
      redisClient = null;
    });

    // Test connection
    await new Promise((resolve, reject) => {
      redisClient.ping((err, result) => {
        if (err) {
          logger.warn('Redis ping failed, continuing without cache:', err.message);
          redisClient = null;
          resolve();
        } else {
          logger.info('Redis cache initialized successfully');
          resolve();
        }
      });
    });
  } catch (error) {
    logger.warn('Failed to initialize Redis, continuing without cache:', error.message);
    redisClient = null;
  }
}

// Cache helper functions
async function getFromCache(key) {
  if (!redisClient) return null;
  try {
    const result = await promisify(redisClient.get).bind(redisClient)(key);
    return result ? JSON.parse(result) : null;
  } catch (error) {
    logger.warn('Cache get error:', error.message);
    return null;
  }
}

async function setCache(key, data, ttl = CACHE_TTL) {
  if (!redisClient) return;
  try {
    await promisify(redisClient.setex).bind(redisClient)(key, ttl, JSON.stringify(data));
  } catch (error) {
    logger.warn('Cache set error:', error.message);
  }
}

async function invalidateCache(pattern) {
  if (!redisClient) return;
  try {
    const keys = await promisify(redisClient.keys).bind(redisClient)(pattern);
    if (keys.length > 0) {
      await promisify(redisClient.del).bind(redisClient)(...keys);
      logger.info(`Invalidated ${keys.length} cache keys matching pattern: ${pattern}`);
    }
  } catch (error) {
    logger.warn('Cache invalidation error:', error.message);
  }
}

// Initialize Redis on startup
initializeRedis();

// Routes
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

// Get all pets with caching
app.get('/pets', async (req, res) => {
  try {
    const cacheKey = 'pets:all';
    
    // Try to get from cache first
    const cachedPets = await getFromCache(cacheKey);
    if (cachedPets) {
      logger.info('Returning pets from cache');
      return res.status(200).json(cachedPets);
    }
    
    const params = {
      TableName: tableName,
    };
    
    const result = await dynamoDB.scan(params).promise();
    
    // Cache the result
    await setCache(cacheKey, result.Items);
    
    res.status(200).json(result.Items);
  } catch (error) {
    logger.error('Error fetching pets:', error);
    res.status(500).json({ error: 'Failed to fetch pets' });
  }
});

// Get pet by ID with caching
app.get('/pets/:id', async (req, res) => {
  try {
    const cacheKey = `pet:${req.params.id}`;
    
    // Try to get from cache first
    const cachedPet = await getFromCache(cacheKey);
    if (cachedPet) {
      logger.info(`Returning pet ${req.params.id} from cache`);
      return res.status(200).json(cachedPet);
    }
    
    const params = {
      TableName: tableName,
      Key: {
        id: req.params.id,
      },
    };
    
    const result = await dynamoDB.get(params).promise();
    
    if (!result.Item) {
      return res.status(404).json({ error: 'Pet not found' });
    }
    
    // Cache the result
    await setCache(cacheKey, result.Item);
    
    res.status(200).json(result.Item);
  } catch (error) {
    logger.error(`Error fetching pet ${req.params.id}:`, error);
    res.status(500).json({ error: 'Failed to fetch pet' });
  }
});

// Create pet with cache invalidation
app.post('/pets', async (req, res) => {
  try {
    const { name, species, breed, age, ownerName, ownerContact } = req.body;
    
    if (!name || !species || !ownerName || !ownerContact) {
      return res.status(400).json({ error: 'Missing required fields' });
    }
    
    const pet = {
      id: uuidv4(),
      name,
      species,
      breed: breed || null,
      age: age || null,
      ownerName,
      ownerContact,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    
    const params = {
      TableName: tableName,
      Item: pet,
    };
    
    await dynamoDB.put(params).promise();
    
    // Invalidate relevant caches
    await invalidateCache('pets:all');
    await setCache(`pet:${pet.id}`, pet);
    
    res.status(201).json(pet);
  } catch (error) {
    logger.error('Error creating pet:', error);
    res.status(500).json({ error: 'Failed to create pet' });
  }
});

// Update pet with cache invalidation
app.put('/pets/:id', async (req, res) => {
  try {
    const { name, species, breed, age, ownerName, ownerContact } = req.body;
    
    // Check if pet exists
    const getParams = {
      TableName: tableName,
      Key: {
        id: req.params.id,
      },
    };
    
    const existingPet = await dynamoDB.get(getParams).promise();
    
    if (!existingPet.Item) {
      return res.status(404).json({ error: 'Pet not found' });
    }
    
    // Update pet
    const updateParams = {
      TableName: tableName,
      Key: {
        id: req.params.id,
      },
      UpdateExpression: 'set #name = :name, species = :species, breed = :breed, age = :age, ownerName = :ownerName, ownerContact = :ownerContact, updatedAt = :updatedAt',
      ExpressionAttributeNames: {
        '#name': 'name', // 'name' is a reserved keyword in DynamoDB
      },
      ExpressionAttributeValues: {
        ':name': name || existingPet.Item.name,
        ':species': species || existingPet.Item.species,
        ':breed': breed || existingPet.Item.breed,
        ':age': age || existingPet.Item.age,
        ':ownerName': ownerName || existingPet.Item.ownerName,
        ':ownerContact': ownerContact || existingPet.Item.ownerContact,
        ':updatedAt': new Date().toISOString(),
      },
      ReturnValues: 'ALL_NEW',
    };
    
    const result = await dynamoDB.update(updateParams).promise();
    
    // Invalidate relevant caches
    await invalidateCache('pets:all');
    await invalidateCache(`pet:${req.params.id}`);
    await setCache(`pet:${req.params.id}`, result.Attributes);
    
    res.status(200).json(result.Attributes);
  } catch (error) {
    logger.error(`Error updating pet ${req.params.id}:`, error);
    res.status(500).json({ error: 'Failed to update pet' });
  }
});

// Delete pet with cache invalidation
app.delete('/pets/:id', async (req, res) => {
  try {
    const params = {
      TableName: tableName,
      Key: {
        id: req.params.id,
      },
      ReturnValues: 'ALL_OLD',
    };
    
    const result = await dynamoDB.delete(params).promise();
    
    if (!result.Attributes) {
      return res.status(404).json({ error: 'Pet not found' });
    }
    
    // Invalidate relevant caches
    await invalidateCache('pets:all');
    await invalidateCache(`pet:${req.params.id}`);
    
    res.status(200).json({ message: 'Pet deleted successfully' });
  } catch (error) {
    logger.error(`Error deleting pet ${req.params.id}:`, error);
    res.status(500).json({ error: 'Failed to delete pet' });
  }
});

// Start server
app.listen(port, () => {
  logger.info(`Pet service listening on port ${port}`);
});

module.exports = app; // For testing
