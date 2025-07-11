// Please see documentation at https://learn.microsoft.com/aspnet/core/client-side/bundling-and-minification
// for details on configuring this project to bundle and minify static web assets.

// Write your JavaScript code.

// Image Upload functionality
document.addEventListener('DOMContentLoaded', function () {
    const saveImageBtn = document.getElementById('saveImageBtn');
    const uploadImageForm = document.getElementById('uploadImageForm');
    const uploadToast = document.getElementById('uploadToast');
    const toastMessage = document.getElementById('toastMessage');
    const uploadModal = document.getElementById('uploadImageModal');
    const deleteConfirmModal = document.getElementById('deleteConfirmModal');
    const confirmDeleteBtn = document.getElementById('confirmDeleteBtn');
    const deleteFileName = document.getElementById('deleteFileName');

    let currentImageId = null;

    if (saveImageBtn) {
        saveImageBtn.addEventListener('click', function () {
            const fileInput = document.getElementById('imageFile');
            const description = document.getElementById('imageDescription').value;
            const altText = document.getElementById('imageAltText').value;

            // Validate form
            if (!fileInput.files[0] || !description || !altText) {
                showToast('Please fill in all fields and select an image file.', 'error');
                return;
            }

            const file = fileInput.files[0];
            
            // Validate file type
            if (!file.type.startsWith('image/')) {
                showToast('Please select a valid image file.', 'error');
                return;
            }

            // Convert file to base64
            const reader = new FileReader();
            reader.onload = function (e) {
                const base64Data = e.target.result;
                
                // Prepare data for upload
                const imageDetail = {
                    FileName: file.name,
                    Description: description,
                    AltText: altText,
                    ImageFullPath: base64Data
                };

                // Upload the image
                uploadImage(imageDetail);
            };
            
            reader.readAsDataURL(file);
        });
    }

    function uploadImage(imageDetail) {
        // Disable save button during upload
        saveImageBtn.disabled = true;
        saveImageBtn.textContent = 'Uploading...';

        fetch('/Home/UploadImage', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                '__RequestVerificationToken': getAntiForgeryToken()
            },
            body: JSON.stringify(imageDetail)
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                showToast('File uploaded successfully!', 'success');
                // Reset form and close modal
                uploadImageForm.reset();
                const modal = bootstrap.Modal.getInstance(uploadModal);
                modal.hide();
                // Refresh page to show new image
                setTimeout(() => {
                    window.location.reload();
                }, 1500);
            } else {
                showToast(data.message || 'Upload failed. Please try again.', 'error');
            }
        })
        .catch(error => {
            console.error('Error uploading image:', error);
            showToast('Upload failed. Please try again.', 'error');
        })
        .finally(() => {
            // Re-enable save button
            saveImageBtn.disabled = false;
            saveImageBtn.textContent = 'Save';
        });
    }

    function showToast(message, type) {
        toastMessage.textContent = message;
        
        // Set toast style based on type
        const toastElement = uploadToast;
        toastElement.className = 'toast';
        if (type === 'success') {
            toastElement.classList.add('bg-success', 'text-white');
        } else if (type === 'error') {
            toastElement.classList.add('bg-danger', 'text-white');
        }
        
        const toast = new bootstrap.Toast(toastElement);
        toast.show();
    }

    function getAntiForgeryToken() {
        // Try to get the anti-forgery token from a meta tag or hidden input
        const token = document.querySelector('input[name="__RequestVerificationToken"]');
        return token ? token.value : '';
    }

    // Handle delete confirmation
    if (confirmDeleteBtn) {
        confirmDeleteBtn.addEventListener('click', function () {
            if (currentImageId) {
                deleteImage(currentImageId);
            }
        });
    }

    // Global function to show delete confirmation
    window.confirmDeleteImage = function(imageId, fileName) {
        currentImageId = imageId;
        deleteFileName.textContent = fileName;
        const modal = new bootstrap.Modal(deleteConfirmModal);
        modal.show();
    };

    function deleteImage(imageId) {
        // Disable delete button during deletion
        confirmDeleteBtn.disabled = true;
        confirmDeleteBtn.textContent = 'Deleting...';

        fetch('/Home/DeleteImage', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                '__RequestVerificationToken': getAntiForgeryToken()
            },
            body: JSON.stringify(imageId)
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                showToast('Image deleted successfully!', 'success');
                // Close modal
                const modal = bootstrap.Modal.getInstance(deleteConfirmModal);
                modal.hide();
                // Refresh page to remove deleted image
                setTimeout(() => {
                    window.location.reload();
                }, 1500);
            } else {
                showToast(data.message || 'Delete failed. Please try again.', 'error');
            }
        })
        .catch(error => {
            console.error('Error deleting image:', error);
            showToast('Delete failed. Please try again.', 'error');
        })
        .finally(() => {
            // Re-enable delete button
            confirmDeleteBtn.disabled = false;
            confirmDeleteBtn.textContent = 'Delete';
            currentImageId = null;
        });
    }
});
