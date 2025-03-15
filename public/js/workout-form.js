/**
 * Workout form handler for the Health & Fitness Tracker
 * Manages the workout form interactions and exercise tracking
 */

// Current workout being built
let currentWorkout = {
    name: '',
    type: '',
    date: new Date(),
    duration: 0,
    calories: 0,
    notes: '',
    exercises: []
};

// Current exercise being added/edited
let currentExerciseIndex = -1;
let isEditingExercise = false;

/**
 * Initialize the workout form functionality
 */
function initWorkoutForm() {
    console.log('Initializing workout form...');
    
    // Set default date to now
    document.getElementById('workout-date').valueAsDate = new Date();
    
    // Add event listeners
    document.getElementById('workout-type').addEventListener('change', handleWorkoutTypeChange);
    document.getElementById('add-exercise-btn').addEventListener('click', openAddExerciseModal);
    document.getElementById('add-set-btn').addEventListener('click', addNewSet);
    document.getElementById('add-workout-form').addEventListener('submit', handleWorkoutFormSubmit);
    document.getElementById('add-exercise-form').addEventListener('submit', handleExerciseFormSubmit);
    document.getElementById('discard-workout-btn').addEventListener('click', discardWorkout);
    
    // Initialize workout object
    resetCurrentWorkout();
}

/**
 * Handle workout type change
 */
function handleWorkoutTypeChange() {
    const workoutType = document.getElementById('workout-type').value;
    
    // Hide all type-specific sections
    document.querySelectorAll('.workout-type-section').forEach(section => {
        section.classList.add('d-none');
    });
    
    // Show the appropriate section
    if (workoutType === 'cardio') {
        document.getElementById('cardio-section').classList.remove('d-none');
        currentWorkout.type = 'cardio';
    } else if (workoutType === 'weights') {
        document.getElementById('weights-section').classList.remove('d-none');
        currentWorkout.type = 'weights';
    }
}

/**
 * Open the add exercise modal
 */
function openAddExerciseModal() {
    // Reset form
    document.getElementById('add-exercise-form').reset();
    
    // Clear existing sets except the first one
    const setsContainer = document.getElementById('exercise-sets');
    const setRows = setsContainer.querySelectorAll('.set-row');
    for (let i = 1; i < setRows.length; i++) {
        setsContainer.removeChild(setRows[i]);
    }
    
    // Reset current exercise index
    currentExerciseIndex = -1;
    isEditingExercise = false;
    
    // Open modal
    const exerciseModal = new bootstrap.Modal(document.getElementById('addExerciseModal'));
    exerciseModal.show();
}

/**
 * Add a new set row to the exercise form
 */
function addNewSet() {
    const setsContainer = document.getElementById('exercise-sets');
    const setCount = setsContainer.querySelectorAll('.set-row').length + 1;
    
    const setRow = document.createElement('div');
    setRow.className = 'set-row row mb-2 align-items-center';
    setRow.setAttribute('data-set', setCount);
    
    setRow.innerHTML = `
        <div class="col-1">
            <span class="set-number">${setCount}</span>
        </div>
        <div class="col-4">
            <input type="number" class="form-control form-control-sm weight-input" placeholder="Weight" min="0" step="0.5">
        </div>
        <div class="col-3">
            <input type="number" class="form-control form-control-sm reps-input" placeholder="Reps" min="1">
        </div>
        <div class="col-3">
            <select class="form-select form-select-sm unit-select">
                <option value="lbs">lbs</option>
                <option value="kg">kg</option>
            </select>
        </div>
        <div class="col-1">
            <button type="button" class="btn btn-sm btn-link text-danger remove-set-btn p-0" title="Remove Set">
                <i class="bi bi-x-circle"></i>
            </button>
        </div>
    `;
    
    // Add event listener to remove button
    setRow.querySelector('.remove-set-btn').addEventListener('click', function() {
        removeSet(this);
    });
    
    setsContainer.appendChild(setRow);
}

/**
 * Remove a set row from the exercise form
 * @param {HTMLElement} button - The remove button that was clicked
 */
function removeSet(button) {
    const setRow = button.closest('.set-row');
    setRow.parentNode.removeChild(setRow);
    
    // Renumber the sets
    const setRows = document.querySelectorAll('.set-row');
    setRows.forEach((row, index) => {
        row.setAttribute('data-set', index + 1);
        row.querySelector('.set-number').textContent = index + 1;
    });
}

/**
 * Handle exercise form submission
 * @param {Event} event - Form submission event
 */
function handleExerciseFormSubmit(event) {
    event.preventDefault();
    
    const exerciseName = document.getElementById('exercise-name').value;
    const sets = [];
    
    // Collect sets data
    document.querySelectorAll('.set-row').forEach(row => {
        const weight = parseFloat(row.querySelector('.weight-input').value) || 0;
        const reps = parseInt(row.querySelector('.reps-input').value) || 0;
        const unit = row.querySelector('.unit-select').value;
        
        if (weight > 0 && reps > 0) {
            sets.push({ weight, reps, unit });
        }
    });
    
    if (exerciseName && sets.length > 0) {
        const exercise = {
            name: exerciseName,
            sets: sets
        };
        
        if (isEditingExercise && currentExerciseIndex >= 0) {
            // Update existing exercise
            currentWorkout.exercises[currentExerciseIndex] = exercise;
        } else {
            // Add new exercise
            currentWorkout.exercises.push(exercise);
        }
        
        // Update the exercise list in the UI
        renderExerciseList();
        
        // Close the modal
        const modal = bootstrap.Modal.getInstance(document.getElementById('addExerciseModal'));
        modal.hide();
    } else {
        showToast('Please enter an exercise name and at least one complete set.', 'danger');
    }
}

/**
 * Render the list of exercises in the workout form
 */
function renderExerciseList() {
    const container = document.getElementById('exercise-list-container');
    const noExercisesMessage = document.getElementById('no-exercises-message');
    
    // Clear existing exercises
    const existingExercises = container.querySelectorAll('.exercise-item');
    existingExercises.forEach(item => container.removeChild(item));
    
    if (currentWorkout.exercises.length > 0) {
        // Hide the no exercises message
        noExercisesMessage.classList.add('d-none');
        
        // Create and append exercise items
        currentWorkout.exercises.forEach((exercise, index) => {
            const exerciseItem = document.createElement('div');
            exerciseItem.className = 'exercise-item card mb-3';
            exerciseItem.setAttribute('data-exercise-index', index);
            
            let setsHtml = '';
            exercise.sets.forEach((set, setIndex) => {
                setsHtml += `
                    <div class="d-flex justify-content-between align-items-center border-bottom py-2">
                        <div>Set ${setIndex + 1}</div>
                        <div>${set.weight} ${set.unit} × ${set.reps} reps</div>
                    </div>
                `;
            });
            
            exerciseItem.innerHTML = `
                <div class="card-header d-flex justify-content-between align-items-center py-2">
                    <h6 class="mb-0">${exercise.name}</h6>
                    <div>
                        <button type="button" class="btn btn-sm btn-link edit-exercise-btn" title="Edit Exercise">
                            <i class="bi bi-pencil"></i>
                        </button>
                        <button type="button" class="btn btn-sm btn-link text-danger remove-exercise-btn" title="Remove Exercise">
                            <i class="bi bi-trash"></i>
                        </button>
                    </div>
                </div>
                <div class="card-body py-2">
                    <div class="sets-summary">
                        ${setsHtml}
                    </div>
                </div>
            `;
            
            // Add event listeners to buttons
            const editBtn = exerciseItem.querySelector('.edit-exercise-btn');
            const removeBtn = exerciseItem.querySelector('.remove-exercise-btn');
            
            editBtn.addEventListener('click', () => editExercise(index));
            removeBtn.addEventListener('click', () => removeExercise(index));
            
            container.appendChild(exerciseItem);
        });
    } else {
        // Show the no exercises message
        noExercisesMessage.classList.remove('d-none');
    }
}

/**
 * Edit an existing exercise
 * @param {number} index - Index of the exercise to edit
 */
function editExercise(index) {
    const exercise = currentWorkout.exercises[index];
    if (!exercise) return;
    
    // Set editing state
    currentExerciseIndex = index;
    isEditingExercise = true;
    
    // Populate form with exercise data
    document.getElementById('exercise-name').value = exercise.name;
    
    // Reset sets container
    const setsContainer = document.getElementById('exercise-sets');
    setsContainer.innerHTML = '';
    
    // Add sets from the exercise
    exercise.sets.forEach((set, i) => {
        const setRow = document.createElement('div');
        setRow.className = 'set-row row mb-2 align-items-center';
        setRow.setAttribute('data-set', i + 1);
        
        setRow.innerHTML = `
            <div class="col-1">
                <span class="set-number">${i + 1}</span>
            </div>
            <div class="col-4">
                <input type="number" class="form-control form-control-sm weight-input" placeholder="Weight" min="0" step="0.5" value="${set.weight}">
            </div>
            <div class="col-3">
                <input type="number" class="form-control form-control-sm reps-input" placeholder="Reps" min="1" value="${set.reps}">
            </div>
            <div class="col-3">
                <select class="form-select form-select-sm unit-select">
                    <option value="lbs" ${set.unit === 'lbs' ? 'selected' : ''}>lbs</option>
                    <option value="kg" ${set.unit === 'kg' ? 'selected' : ''}>kg</option>
                </select>
            </div>
            <div class="col-1">
                ${i > 0 ? `
                    <button type="button" class="btn btn-sm btn-link text-danger remove-set-btn p-0" title="Remove Set">
                        <i class="bi bi-x-circle"></i>
                    </button>
                ` : ''}
            </div>
        `;
        
        // Add event listener to remove button if not the first set
        if (i > 0) {
            setRow.querySelector('.remove-set-btn').addEventListener('click', function() {
                removeSet(this);
            });
        }
        
        setsContainer.appendChild(setRow);
    });
    
    // Open modal
    const exerciseModal = new bootstrap.Modal(document.getElementById('addExerciseModal'));
    exerciseModal.show();
}

/**
 * Remove an exercise from the workout
 * @param {number} index - Index of the exercise to remove
 */
function removeExercise(index) {
    if (confirm('Are you sure you want to remove this exercise?')) {
        currentWorkout.exercises.splice(index, 1);
        renderExerciseList();
    }
}

/**
 * Handle workout form submission
 * @param {Event} event - Form submission event
 */
function handleWorkoutFormSubmit(event) {
    event.preventDefault();
    
    currentWorkout.name = document.getElementById('workout-name').value;
    currentWorkout.date = new Date(document.getElementById('workout-date').value);
    
    // Different fields based on workout type
    if (currentWorkout.type === 'cardio') {
        currentWorkout.activity = document.getElementById('cardio-activity').value;
        currentWorkout.duration = parseInt(document.getElementById('cardio-duration').value) || 0;
        currentWorkout.calories = parseInt(document.getElementById('cardio-calories').value) || 0;
        currentWorkout.distance = parseFloat(document.getElementById('cardio-distance').value) || 0;
        currentWorkout.pace = document.getElementById('cardio-pace').value;
        currentWorkout.heartRate = parseInt(document.getElementById('cardio-heart-rate').value) || 0;
        currentWorkout.notes = document.getElementById('cardio-notes').value;
    } else if (currentWorkout.type === 'weights') {
        currentWorkout.duration = parseInt(document.getElementById('weights-duration').value) || 0;
        currentWorkout.calories = parseInt(document.getElementById('weights-calories').value) || 0;
        currentWorkout.notes = document.getElementById('weights-notes').value;
    }
    
    // Validate the workout
    if (!validateWorkout()) {
        return;
    }
    
    // Create the activity object
    const activity = createActivityFromWorkout();
    
    // Add the activity to the tracker
    if (fitnessTracker.addActivity(activity)) {
        // Update the UI
        updateDashboard();
        
        // Reset the form and workout object
        document.getElementById('add-workout-form').reset();
        resetCurrentWorkout();
        
        // Hide the modal
        const modal = bootstrap.Modal.getInstance(document.getElementById('addWorkoutModal'));
        modal.hide();
        
        // Show success message
        showToast('Workout added successfully!', 'success');
    } else {
        showToast('Failed to add workout. Please check all fields.', 'danger');
    }
}

/**
 * Validate the workout data before submission
 * @returns {boolean} True if the workout is valid
 */
function validateWorkout() {
    // Common validations
    if (!currentWorkout.name || !currentWorkout.type || !currentWorkout.date) {
        showToast('Please enter a workout name, type, and date.', 'danger');
        return false;
    }
    
    // Type-specific validations
    if (currentWorkout.type === 'cardio') {
        if (!currentWorkout.activity || currentWorkout.duration <= 0) {
            showToast('Please select an activity and enter a duration.', 'danger');
            return false;
        }
    } else if (currentWorkout.type === 'weights') {
        if (currentWorkout.exercises.length === 0) {
            showToast('Please add at least one exercise to your workout.', 'danger');
            return false;
        }
        
        if (currentWorkout.duration <= 0) {
            showToast('Please enter the workout duration.', 'danger');
            return false;
        }
    }
    
    return true;
}

/**
 * Create an Activity object from the current workout
 * @returns {Activity} The created Activity object
 */
function createActivityFromWorkout() {
    let name, type;
    
    if (currentWorkout.type === 'cardio') {
        name = `${currentWorkout.activity.charAt(0).toUpperCase() + currentWorkout.activity.slice(1)}`;
        type = currentWorkout.activity;
    } else {
        name = currentWorkout.name;
        type = 'weights';
    }
    
    const activity = new Activity(
        name,
        currentWorkout.calories,
        currentWorkout.duration,
        type,
        currentWorkout.date
    );
    
    // Set workout details
    activity.workoutDetails = {
        category: currentWorkout.type,
        exercises: JSON.parse(JSON.stringify(currentWorkout.exercises)), // Deep copy
        notes: currentWorkout.notes || ''
    };
    
    // Add additional cardio-specific details
    if (currentWorkout.type === 'cardio') {
        activity.workoutDetails.distance = currentWorkout.distance;
        activity.workoutDetails.pace = currentWorkout.pace;
        activity.workoutDetails.heartRate = currentWorkout.heartRate;
    }
    
    return activity;
}

/**
 * Reset the current workout object
 */
function resetCurrentWorkout() {
    currentWorkout = {
        name: '',
        type: '',
        date: new Date(),
        duration: 0,
        calories: 0,
        notes: '',
        exercises: []
    };
    
    // Hide type-specific sections
    document.querySelectorAll('.workout-type-section').forEach(section => {
        section.classList.add('d-none');
    });
    
    // Reset exercise list
    const noExercisesMessage = document.getElementById('no-exercises-message');
    if (noExercisesMessage) {
        noExercisesMessage.classList.remove('d-none');
    }
    
    const container = document.getElementById('exercise-list-container');
    if (container) {
        const existingExercises = container.querySelectorAll('.exercise-item');
        existingExercises.forEach(item => container.removeChild(item));
    }
}

/**
 * Discard the current workout
 */
function discardWorkout() {
    if (confirm('Are you sure you want to discard this workout? All data will be lost.')) {
        // Reset the form and workout object
        document.getElementById('add-workout-form').reset();
        resetCurrentWorkout();
        
        // Hide the modal
        const modal = bootstrap.Modal.getInstance(document.getElementById('addWorkoutModal'));
        modal.hide();
    }
}

// Initialize workout form when the DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    // Initialize workout form
    initWorkoutForm();
});