import React, { useState, useEffect } from 'react';
import { Link as RouterLink } from 'react-router-dom';
import {
  Container,
  Typography,
  Button,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Box,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  TextField,
  CircularProgress,
  Alert,
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import EditIcon from '@mui/icons-material/Edit';
import DeleteIcon from '@mui/icons-material/Delete';
import axios from 'axios';

const API_URL = '/api/pet';

function Pets() {
  const [pets, setPets] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [openDialog, setOpenDialog] = useState(false);
  const [deleteId, setDeleteId] = useState(null);
  const [formOpen, setFormOpen] = useState(false);
  const [formData, setFormData] = useState({
    name: '',
    species: '',
    breed: '',
    age: '',
    ownerName: '',
    ownerContact: '',
  });

  useEffect(() => {
    fetchPets();
  }, []);

  const fetchPets = async () => {
    try {
      setLoading(true);
      const response = await axios.get(API_URL);
      setPets(response.data);
      setError(null);
    } catch (err) {
      console.error('Error fetching pets:', err);
      setError('Failed to fetch pets. Please try again later.');
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteClick = (id) => {
    setDeleteId(id);
    setOpenDialog(true);
  };

  const handleDeleteConfirm = async () => {
    try {
      await axios.delete(`${API_URL}/${deleteId}`);
      setPets(pets.filter(pet => pet.id !== deleteId));
      setOpenDialog(false);
      setDeleteId(null);
    } catch (err) {
      console.error('Error deleting pet:', err);
      setError('Failed to delete pet. Please try again later.');
    }
  };

  const handleDialogClose = () => {
    setOpenDialog(false);
    setDeleteId(null);
  };

  const handleFormOpen = (pet = null) => {
    if (pet) {
      setFormData({
        id: pet.id,
        name: pet.name,
        species: pet.species,
        breed: pet.breed || '',
        age: pet.age || '',
        ownerName: pet.ownerName,
        ownerContact: pet.ownerContact,
      });
    } else {
      setFormData({
        name: '',
        species: '',
        breed: '',
        age: '',
        ownerName: '',
        ownerContact: '',
      });
    }
    setFormOpen(true);
  };

  const handleFormClose = () => {
    setFormOpen(false);
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData({
      ...formData,
      [name]: value,
    });
  };

  const handleFormSubmit = async (e) => {
    e.preventDefault();
    try {
      if (formData.id) {
        // Update existing pet
        await axios.put(`${API_URL}/${formData.id}`, formData);
      } else {
        // Create new pet
        await axios.post(API_URL, formData);
      }
      fetchPets();
      setFormOpen(false);
    } catch (err) {
      console.error('Error saving pet:', err);
      setError('Failed to save pet. Please try again later.');
    }
  };

  return (
    <Container maxWidth="lg">
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
        <Typography variant="h4" component="h1" gutterBottom>
          Pets
        </Typography>
        <Button
          variant="contained"
          color="primary"
          startIcon={<AddIcon />}
          onClick={() => handleFormOpen()}
        >
          Add Pet
        </Button>
      </Box>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', mt: 4 }}>
          <CircularProgress />
        </Box>
      ) : (
        <TableContainer component={Paper}>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Name</TableCell>
                <TableCell>Species</TableCell>
                <TableCell>Breed</TableCell>
                <TableCell>Age</TableCell>
                <TableCell>Owner</TableCell>
                <TableCell>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {pets.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={6} align="center">
                    No pets found. Add a new pet to get started.
                  </TableCell>
                </TableRow>
              ) : (
                pets.map((pet) => (
                  <TableRow key={pet.id}>
                    <TableCell component="th" scope="row">
                      <RouterLink to={`/pets/${pet.id}`} style={{ textDecoration: 'none', color: 'inherit' }}>
                        {pet.name}
                      </RouterLink>
                    </TableCell>
                    <TableCell>{pet.species}</TableCell>
                    <TableCell>{pet.breed || '-'}</TableCell>
                    <TableCell>{pet.age || '-'}</TableCell>
                    <TableCell>{pet.ownerName}</TableCell>
                    <TableCell>
                      <Button
                        size="small"
                        startIcon={<EditIcon />}
                        onClick={() => handleFormOpen(pet)}
                        sx={{ mr: 1 }}
                      >
                        Edit
                      </Button>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </TableContainer>
      )}

      {/* Delete Confirmation Dialog */}
      <Dialog
        open={openDialog}
        onClose={handleDialogClose}
      >
        <DialogTitle>Confirm Delete</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Are you sure you want to delete this pet? This action cannot be undone.
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleDialogClose}>Cancel</Button>
          <Button onClick={handleDeleteConfirm} color="error" autoFocus>
            Delete
          </Button>
        </DialogActions>
      </Dialog>

      {/* Add/Edit Pet Form Dialog */}
      <Dialog open={formOpen} onClose={handleFormClose} maxWidth="sm" fullWidth>
        <DialogTitle>{formData.id ? 'Edit Pet' : 'Add New Pet'}</DialogTitle>
        <form onSubmit={handleFormSubmit}>
          <DialogContent>
            <TextField
              autoFocus
              margin="dense"
              name="name"
              label="Pet Name"
              type="text"
              fullWidth
              variant="outlined"
              value={formData.name}
              onChange={handleInputChange}
              required
            />
            <TextField
              margin="dense"
              name="species"
              label="Species"
              type="text"
              fullWidth
              variant="outlined"
              value={formData.species}
              onChange={handleInputChange}
              required
            />
            <TextField
              margin="dense"
              name="breed"
              label="Breed"
              type="text"
              fullWidth
              variant="outlined"
              value={formData.breed}
              onChange={handleInputChange}
            />
            <TextField
              margin="dense"
              name="age"
              label="Age"
              type="number"
              fullWidth
              variant="outlined"
              value={formData.age}
              onChange={handleInputChange}
            />
            <TextField
              margin="dense"
              name="ownerName"
              label="Owner Name"
              type="text"
              fullWidth
              variant="outlined"
              value={formData.ownerName}
              onChange={handleInputChange}
              required
            />
            <TextField
              margin="dense"
              name="ownerContact"
              label="Owner Contact"
              type="text"
              fullWidth
              variant="outlined"
              value={formData.ownerContact}
              onChange={handleInputChange}
              required
            />
          </DialogContent>
          <DialogActions>
            <Button onClick={handleFormClose}>Cancel</Button>
            <Button type="submit" variant="contained" color="primary">
              {formData.id ? 'Update' : 'Create'}
            </Button>
          </DialogActions>
        </form>
      </Dialog>
    </Container>
  );
}

export default Pets;
