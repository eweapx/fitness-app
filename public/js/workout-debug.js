/**
 * Workout Test Module - For debugging purposes
 */

// Test function to ensure basic class initialization works
function testWorkoutManagerInitialization() {
  console.log("Testing WorkoutManager initialization...");
  
  try {
    // Create a new instance of WorkoutManager
    const manager = new WorkoutManager();
    console.log("✅ WorkoutManager initialized successfully");
    return true;
  } catch (error) {
    console.error("❌ Error initializing WorkoutManager:", error);
    return false;
  }
}

// Test function to ensure basic routine creation works
function testWorkoutRoutineCreation() {
  console.log("Testing WorkoutRoutine creation...");
  
  try {
    // Create a new instance of WorkoutRoutine
    const routine = new WorkoutRoutine(
      null,
      "Test Routine",
      "Test Description",
      [],
      new Date(),
      null
    );
    console.log("✅ WorkoutRoutine created successfully");
    return true;
  } catch (error) {
    console.error("❌ Error creating WorkoutRoutine:", error);
    return false;
  }
}

// Run tests when this script loads
document.addEventListener('DOMContentLoaded', () => {
  console.log("🔍 Running workout-debug.js diagnostics...");
  
  // Add a small delay to ensure other scripts have loaded first
  setTimeout(() => {
    let allTestsPassed = true;
    
    if (!testWorkoutManagerInitialization()) {
      allTestsPassed = false;
    }
    
    if (!testWorkoutRoutineCreation()) {
      allTestsPassed = false;
    }
    
    if (allTestsPassed) {
      console.log("✅ All workout system initialization tests passed!");
    } else {
      console.error("❌ Some workout system tests failed. Check specific error messages above.");
    }
  }, 500);
});