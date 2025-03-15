/**
 * Authentication module for the Health & Fitness Tracker
 * Handles user login, logout, registration, and session management
 */

// Check if the user is authenticated
async function checkAuth() {
    try {
        const response = await fetch('/api/auth/current-user');
        const data = await response.json();
        
        if (data.success) {
            // User is authenticated, update UI
            showAuthenticatedUI(data.user);
            return true;
        } else {
            // User is not authenticated, redirect to login
            redirectToLogin();
            return false;
        }
    } catch (error) {
        console.error('Error checking authentication:', error);
        redirectToLogin();
        return false;
    }
}

// Show authenticated UI with user information
function showAuthenticatedUI(user) {
    // Update profile dropdown with user's name
    const profileButton = document.getElementById('profileDropdown');
    if (profileButton) {
        profileButton.innerHTML = `
            <i class="bi bi-person-circle me-1"></i> ${user.name}
        `;
    }
    
    // Store user data in localStorage for convenience
    localStorage.setItem('currentUser', JSON.stringify(user));
    
    // You can add more UI updates here based on user data
    updateUserSettings(user);
}

// Update user settings based on user data
function updateUserSettings(user) {
    // Set user preferences if they exist
    if (user.preferences) {
        // Apply dark mode if user prefers it
        if (user.preferences.darkMode === true) {
            document.body.classList.add('dark-mode');
        } else if (user.preferences.darkMode === false) {
            document.body.classList.remove('dark-mode');
        }
        
        // Apply other preferences here
    }
}

// Redirect to login page
function redirectToLogin() {
    // Optionally show a message before redirecting
    const statusMessage = document.getElementById('status-message');
    if (statusMessage) {
        statusMessage.innerHTML = `
            <div class="alert alert-warning">
                Please log in to access your fitness data
            </div>
        `;
    }
    
    // Remove user data from localStorage
    localStorage.removeItem('currentUser');
    
    // Redirect after a short delay
    setTimeout(() => {
        window.location.href = '/login.html';
    }, 2000);
}

// Handle sign out
async function signOut() {
    try {
        const response = await fetch('/api/auth/logout', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            }
        });
        
        const data = await response.json();
        
        if (data.success) {
            // Clear user data and redirect to login
            localStorage.removeItem('currentUser');
            window.location.href = '/login.html';
        } else {
            // Show error message
            const statusMessage = document.getElementById('status-message');
            if (statusMessage) {
                statusMessage.innerHTML = `
                    <div class="alert alert-danger">
                        ${data.message || 'Error signing out'}
                    </div>
                `;
            }
        }
    } catch (error) {
        console.error('Error signing out:', error);
        // Show error message
        const statusMessage = document.getElementById('status-message');
        if (statusMessage) {
            statusMessage.innerHTML = `
                <div class="alert alert-danger">
                    An error occurred while signing out. Please try again.
                </div>
            `;
        }
    }
}

// Set up event listeners for authentication actions
function setupAuthEvents() {
    // Sign out button
    const signOutBtn = document.getElementById('sign-out-btn');
    if (signOutBtn) {
        signOutBtn.addEventListener('click', (e) => {
            e.preventDefault();
            signOut();
        });
    }
}

// Initialize authentication on page load
document.addEventListener('DOMContentLoaded', () => {
    checkAuth();
    setupAuthEvents();
});