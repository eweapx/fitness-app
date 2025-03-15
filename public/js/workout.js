/**
 * Workout and Routines Module for the Health & Fitness Tracker
 */

/**
 * WorkoutRoutine class for storing workout routines
 */
class WorkoutRoutine {
  /**
   * Create a new workout routine
   * @param {string} id - Unique identifier
   * @param {string} name - Routine name
   * @param {string} description - Routine description
   * @param {Array} exercises - List of exercises in the routine
   * @param {Date} createdAt - Date when the routine was created
   * @param {Date} lastUsed - Date when the routine was last used
   */
  constructor(id = null, name, description, exercises = [], createdAt = new Date(), lastUsed = null) {
    this.id = id || generateUUID();
    this.name = name;
    this.description = description;
    this.exercises = exercises;
    this.createdAt = createdAt;
    this.lastUsed = lastUsed;
  }

  /**
   * Add an exercise to the routine
   * @param {Object} exercise - Exercise details
   * @returns {boolean} Success indicator
   */
  addExercise(exercise) {
    if (!exercise.name) {
      return false;
    }
    
    // Generate ID if not provided
    if (!exercise.id) {
      exercise.id = generateUUID();
    }
    
    this.exercises.push(exercise);
    return true;
  }

  /**
   * Remove an exercise from the routine
   * @param {string} exerciseId - ID of the exercise to remove
   * @returns {boolean} Success indicator
   */
  removeExercise(exerciseId) {
    const initialLength = this.exercises.length;
    this.exercises = this.exercises.filter(ex => ex.id !== exerciseId);
    return initialLength !== this.exercises.length;
  }

  /**
   * Reorder exercises in the routine
   * @param {number} fromIndex - Original position
   * @param {number} toIndex - New position
   * @returns {boolean} Success indicator
   */
  reorderExercise(fromIndex, toIndex) {
    if (fromIndex < 0 || fromIndex >= this.exercises.length || 
        toIndex < 0 || toIndex >= this.exercises.length) {
      return false;
    }
    
    const [removed] = this.exercises.splice(fromIndex, 1);
    this.exercises.splice(toIndex, 0, removed);
    return true;
  }

  /**
   * Get a summary description of the routine
   * @param {number} maxExercises - Maximum number of exercises to include in summary
   * @returns {string} Summary description
   */
  getSummary(maxExercises = 3) {
    if (this.exercises.length === 0) {
      return "No exercises added yet";
    }
    
    const exerciseNames = this.exercises.slice(0, maxExercises).map(ex => ex.name);
    let summary = exerciseNames.join(", ");
    
    if (this.exercises.length > maxExercises) {
      summary += ` and ${this.exercises.length - maxExercises} more`;
    }
    
    return summary;
  }

  /**
   * Update the last used date to now
   */
  updateLastUsed() {
    this.lastUsed = new Date();
  }
}

/**
 * WorkoutManager class to manage workout routines and sessions
 */
class WorkoutManager {
  constructor() {
    this.routines = [];
    this.currentWorkout = null;
    this.exerciseDatabase = [
      // Default exercise library
      { id: "ex1", name: "Bench Press", category: "chest", equipment: "barbell" },
      { id: "ex2", name: "Squats", category: "legs", equipment: "barbell" },
      { id: "ex3", name: "Deadlift", category: "back", equipment: "barbell" },
      { id: "ex4", name: "Pull-ups", category: "back", equipment: "bodyweight" },
      { id: "ex5", name: "Push-ups", category: "chest", equipment: "bodyweight" },
      { id: "ex6", name: "Dumbbell Rows", category: "back", equipment: "dumbbell" },
      { id: "ex7", name: "Shoulder Press", category: "shoulders", equipment: "barbell" },
      { id: "ex8", name: "Lunges", category: "legs", equipment: "bodyweight" },
      { id: "ex9", name: "Bicep Curls", category: "arms", equipment: "dumbbell" },
      { id: "ex10", name: "Tricep Extensions", category: "arms", equipment: "cable" }
    ];
    
    // Load saved data
    this.loadFromLocalStorage();
  }

  /**
   * Add a new workout routine
   * @param {WorkoutRoutine} routine - The routine to add
   * @returns {boolean} Success indicator
   */
  addRoutine(routine) {
    if (!routine.name) {
      return false;
    }
    
    this.routines.push(routine);
    this.saveToLocalStorage();
    return true;
  }

  /**
   * Get all workout routines
   * @returns {Array} List of workout routines
   */
  getRoutines() {
    return [...this.routines];
  }

  /**
   * Get a specific routine by ID
   * @param {string} id - Routine ID
   * @returns {WorkoutRoutine|null} The routine or null if not found
   */
  getRoutineById(id) {
    return this.routines.find(routine => routine.id === id) || null;
  }

  /**
   * Update an existing routine
   * @param {string} id - ID of the routine to update
   * @param {Object} updates - Properties to update
   * @returns {boolean} Success indicator
   */
  updateRoutine(id, updates) {
    const index = this.routines.findIndex(routine => routine.id === id);
    if (index === -1) {
      return false;
    }
    
    // Apply updates to the routine
    this.routines[index] = { ...this.routines[index], ...updates };
    this.saveToLocalStorage();
    return true;
  }

  /**
   * Delete a routine
   * @param {string} id - ID of the routine to delete
   * @returns {boolean} Success indicator
   */
  deleteRoutine(id) {
    const initialLength = this.routines.length;
    this.routines = this.routines.filter(routine => routine.id !== id);
    const success = initialLength !== this.routines.length;
    
    if (success) {
      this.saveToLocalStorage();
    }
    
    return success;
  }

  /**
   * Start a new workout session
   * @param {WorkoutRoutine|null} routine - Optional routine to start with
   * @returns {Object} The current workout session
   */
  startWorkout(routine = null) {
    // Create a new workout session
    this.currentWorkout = {
      id: generateUUID(),
      startTime: new Date(),
      endTime: null,
      exercises: [],
      notes: "",
      completed: false
    };
    
    // If a routine was provided, copy its exercises to the workout
    if (routine) {
      routine.exercises.forEach(exercise => {
        this.addExerciseToWorkout({
          id: generateUUID(),
          name: exercise.name,
          sets: this.generateSetsFromTemplate(exercise),
          notes: exercise.notes || "",
          originalExerciseId: exercise.id
        });
      });
      
      // Update the last used date of the routine
      routine.updateLastUsed();
      this.updateRoutine(routine.id, { lastUsed: routine.lastUsed });
    }
    
    return this.currentWorkout;
  }

  /**
   * Generate sets based on an exercise template
   * @param {Object} exercise - Exercise template
   * @returns {Array} Generated sets
   */
  generateSetsFromTemplate(exercise) {
    // If the exercise has predefined sets, use those
    if (exercise.sets && exercise.sets.length > 0) {
      return exercise.sets.map(set => ({
        weight: set.weight || 0,
        reps: set.reps || 0,
        completed: false
      }));
    }
    
    // Otherwise generate default sets (3 sets of 10 reps)
    return [
      { weight: 0, reps: 10, completed: false },
      { weight: 0, reps: 10, completed: false },
      { weight: 0, reps: 10, completed: false }
    ];
  }

  /**
   * Add an exercise to the current workout
   * @param {Object} exercise - Exercise details
   * @returns {boolean} Success indicator
   */
  addExerciseToWorkout(exercise) {
    if (!this.currentWorkout) {
      return false;
    }
    
    // If no sets provided, add default sets
    if (!exercise.sets || !exercise.sets.length) {
      exercise.sets = [
        { weight: 0, reps: 10, completed: false },
        { weight: 0, reps: 10, completed: false },
        { weight: 0, reps: 10, completed: false }
      ];
    }
    
    this.currentWorkout.exercises.push(exercise);
    return true;
  }

  /**
   * Update an exercise in the current workout
   * @param {string} exerciseId - ID of the exercise to update
   * @param {Object} updates - Fields to update
   * @returns {boolean} Success indicator
   */
  updateExerciseInWorkout(exerciseId, updates) {
    if (!this.currentWorkout) {
      return false;
    }
    
    const index = this.currentWorkout.exercises.findIndex(ex => ex.id === exerciseId);
    if (index === -1) {
      return false;
    }
    
    this.currentWorkout.exercises[index] = { ...this.currentWorkout.exercises[index], ...updates };
    return true;
  }

  /**
   * Update a set in the current workout
   * @param {string} exerciseId - ID of the exercise containing the set
   * @param {number} setIndex - Index of the set to update
   * @param {Object} updates - Fields to update (weight, reps, completed)
   * @returns {boolean} Success indicator
   */
  updateSetInWorkout(exerciseId, setIndex, updates) {
    if (!this.currentWorkout) {
      return false;
    }
    
    const exercise = this.currentWorkout.exercises.find(ex => ex.id === exerciseId);
    if (!exercise || setIndex < 0 || setIndex >= exercise.sets.length) {
      return false;
    }
    
    exercise.sets[setIndex] = { ...exercise.sets[setIndex], ...updates };
    return true;
  }

  /**
   * Add a new set to an exercise in the current workout
   * @param {string} exerciseId - ID of the exercise
   * @param {Object} set - Set details (weight, reps)
   * @returns {boolean} Success indicator
   */
  addSetToExercise(exerciseId, set = { weight: 0, reps: 0, completed: false }) {
    if (!this.currentWorkout) {
      return false;
    }
    
    const exercise = this.currentWorkout.exercises.find(ex => ex.id === exerciseId);
    if (!exercise) {
      return false;
    }
    
    exercise.sets.push(set);
    return true;
  }

  /**
   * Remove a set from an exercise in the current workout
   * @param {string} exerciseId - ID of the exercise
   * @param {number} setIndex - Index of the set to remove
   * @returns {boolean} Success indicator
   */
  removeSetFromExercise(exerciseId, setIndex) {
    if (!this.currentWorkout) {
      return false;
    }
    
    const exercise = this.currentWorkout.exercises.find(ex => ex.id === exerciseId);
    if (!exercise || setIndex < 0 || setIndex >= exercise.sets.length) {
      return false;
    }
    
    exercise.sets.splice(setIndex, 1);
    return true;
  }

  /**
   * Complete the current workout
   * @param {string} notes - Optional notes about the workout
   * @returns {Object} The completed workout
   */
  completeWorkout(notes = "") {
    if (!this.currentWorkout) {
      return null;
    }
    
    this.currentWorkout.endTime = new Date();
    this.currentWorkout.notes = notes;
    this.currentWorkout.completed = true;
    
    // Calculate duration in seconds
    const durationMs = this.currentWorkout.endTime - this.currentWorkout.startTime;
    this.currentWorkout.duration = Math.floor(durationMs / 1000);
    
    // Calculate total volume (weight * reps across all sets)
    let totalVolume = 0;
    let completedSets = 0;
    let totalSets = 0;
    
    this.currentWorkout.exercises.forEach(exercise => {
      exercise.sets.forEach(set => {
        totalSets++;
        if (set.completed) {
          completedSets++;
          totalVolume += set.weight * set.reps;
        }
      });
    });
    
    this.currentWorkout.totalVolume = totalVolume;
    this.currentWorkout.completionRate = totalSets > 0 ? (completedSets / totalSets) : 0;
    
    // Convert the workout to an activity for the main tracker
    const activity = new Activity(
      "Workout: " + (this.currentWorkout.routineName || "Custom"),
      this.estimateCaloriesBurned(this.currentWorkout),
      Math.floor(this.currentWorkout.duration / 60), // Convert seconds to minutes
      "weights",
      this.currentWorkout.startTime
    );
    
    // Add workout details to the activity
    activity.workoutDetails = {
      exercises: this.currentWorkout.exercises.map(ex => ({
        name: ex.name,
        sets: ex.sets.filter(set => set.completed).length,
        totalSets: ex.sets.length,
        volume: ex.sets.reduce((sum, set) => sum + (set.weight * set.reps), 0)
      })),
      totalVolume: this.currentWorkout.totalVolume,
      duration: this.currentWorkout.duration
    };
    
    // Add the activity to the fitness tracker
    if (window.fitnessTracker) {
      window.fitnessTracker.addActivity(activity);
    }
    
    // Store the completed workout in the workout history
    this.saveWorkoutToHistory(this.currentWorkout);
    
    // Clear the current workout
    const completedWorkout = { ...this.currentWorkout };
    this.currentWorkout = null;
    
    return completedWorkout;
  }

  /**
   * Discard the current workout session without saving
   */
  discardWorkout() {
    this.currentWorkout = null;
  }

  /**
   * Estimate calories burned during a workout
   * @param {Object} workout - The workout to estimate calories for
   * @returns {number} Estimated calories burned
   */
  estimateCaloriesBurned(workout) {
    if (!workout) {
      return 0;
    }
    
    // Simple estimation based on duration
    // A more accurate model would consider intensity, weight, and exercise types
    const minutes = Math.floor(workout.duration / 60);
    
    // Average calorie burn rate for weight training: ~5 calories per minute
    return minutes * 5;
  }

  /**
   * Find exercises in the database by name or category
   * @param {string} query - Search query
   * @returns {Array} Matching exercises
   */
  findExercises(query) {
    if (!query || query.trim() === "") {
      return this.exerciseDatabase;
    }
    
    query = query.toLowerCase().trim();
    
    return this.exerciseDatabase.filter(exercise => 
      exercise.name.toLowerCase().includes(query) || 
      exercise.category.toLowerCase().includes(query)
    );
  }

  /**
   * Add a custom exercise to the database
   * @param {Object} exercise - Exercise details
   * @returns {boolean} Success indicator
   */
  addCustomExercise(exercise) {
    if (!exercise.name) {
      return false;
    }
    
    // Generate ID if not provided
    if (!exercise.id) {
      exercise.id = generateUUID();
    }
    
    // Set default category if not provided
    if (!exercise.category) {
      exercise.category = "custom";
    }
    
    this.exerciseDatabase.push(exercise);
    this.saveToLocalStorage();
    return true;
  }

  /**
   * Calculate barbell plate configuration
   * @param {number} targetWeight - The target weight to achieve
   * @param {number} barWeight - Weight of the barbell (default: 45lbs)
   * @param {Array} availablePlates - Available plate weights in descending order
   * @returns {Array} Plates to add to each side of the bar
   */
  calculatePlatesNeeded(targetWeight, barWeight = 45, availablePlates = [45, 35, 25, 10, 5, 2.5]) {
    // Sort plates in descending order
    availablePlates.sort((a, b) => b - a);
    
    // Weight that needs to be added with plates (divide by 2 for each side)
    const plateWeight = Math.max(0, targetWeight - barWeight) / 2;
    
    const plates = [];
    let remainingWeight = plateWeight;
    
    // Greedy algorithm to select plates
    for (const plate of availablePlates) {
      while (remainingWeight >= plate) {
        plates.push(plate);
        remainingWeight -= plate;
      }
    }
    
    return plates;
  }

  /**
   * Save workout history to localStorage
   * @param {Object} workout - Completed workout to save
   */
  saveWorkoutToHistory(workout) {
    const history = JSON.parse(localStorage.getItem('workoutHistory') || '[]');
    history.push(workout);
    localStorage.setItem('workoutHistory', JSON.stringify(history));
  }

  /**
   * Get workout history
   * @param {number} limit - Maximum number of workouts to return
   * @returns {Array} Workout history
   */
  getWorkoutHistory(limit = 0) {
    const history = JSON.parse(localStorage.getItem('workoutHistory') || '[]');
    
    // Sort by date, newest first
    history.sort((a, b) => new Date(b.startTime) - new Date(a.startTime));
    
    return limit > 0 ? history.slice(0, limit) : history;
  }

  /**
   * Get the current workout session
   * @returns {Object|null} Current workout or null if none active
   */
  getCurrentWorkout() {
    return this.currentWorkout;
  }
  
  /**
   * Get workout by ID
   * @param {string} id - ID of the workout to retrieve
   * @returns {Object|null} The workout object or null if not found
   */
  getWorkoutById(id) {
    // If current workout matches the ID, return it
    if (this.currentWorkout && this.currentWorkout.id === id) {
      return this.currentWorkout;
    }
    
    // Otherwise return null as we only track one active workout at a time
    return null;
  }

  /**
   * Save data to localStorage
   */
  saveToLocalStorage() {
    try {
      // Convert routines to plain objects
      const routinesData = this.routines.map(routine => ({
        id: routine.id,
        name: routine.name,
        description: routine.description,
        exercises: routine.exercises,
        createdAt: routine.createdAt,
        lastUsed: routine.lastUsed
      }));
      
      localStorage.setItem('workoutRoutines', JSON.stringify(routinesData));
      localStorage.setItem('exerciseDatabase', JSON.stringify(this.exerciseDatabase));
    } catch (error) {
      console.error('Error saving workout data to localStorage:', error);
    }
  }

  /**
   * Load data from localStorage
   */
  loadFromLocalStorage() {
    try {
      // Load routines
      const routinesData = JSON.parse(localStorage.getItem('workoutRoutines') || '[]');
      this.routines = routinesData.map(data => {
        const routine = new WorkoutRoutine(
          data.id,
          data.name,
          data.description,
          data.exercises,
          new Date(data.createdAt),
          data.lastUsed ? new Date(data.lastUsed) : null
        );
        return routine;
      });
      
      // Load exercise database
      const exerciseDbData = JSON.parse(localStorage.getItem('exerciseDatabase'));
      if (exerciseDbData && Array.isArray(exerciseDbData)) {
        this.exerciseDatabase = exerciseDbData;
      }
    } catch (error) {
      console.error('Error loading workout data from localStorage:', error);
      // Reset to default state on error
      this.routines = [];
    }
  }
}

/**
 * Export a sample workout plan that can be used for testing
 * @returns {WorkoutRoutine} A sample workout routine
 */
function createSampleWorkoutPlan() {
  const routine = new WorkoutRoutine(
    generateUUID(),
    "Beginner Full Body",
    "A full body workout for beginners, targeting all major muscle groups."
  );
  
  routine.addExercise({
    name: "Bench Press",
    sets: [
      { weight: 45, reps: 10 },
      { weight: 45, reps: 10 },
      { weight: 45, reps: 10 }
    ],
    notes: "Focus on form, keep elbows at 45 degrees."
  });
  
  routine.addExercise({
    name: "Squats",
    sets: [
      { weight: 65, reps: 8 },
      { weight: 65, reps: 8 },
      { weight: 65, reps: 8 }
    ],
    notes: "Keep weight on heels, go to parallel depth."
  });
  
  routine.addExercise({
    name: "Pull-ups",
    sets: [
      { weight: 0, reps: 5 },
      { weight: 0, reps: 5 },
      { weight: 0, reps: 5 }
    ],
    notes: "Use assisted machine if needed."
  });
  
  return routine;
}