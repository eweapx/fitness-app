/**
 * Fitness Tracker App - Main JavaScript
 * 
 * This file handles all UI interactions and app functionality for the comprehensive health app,
 * including activity tracking, nutrition, sleep tracking, and bad habit tracking.
 */

// Global application state
const app = {
  // Current active tab
  currentTab: 'dashboard',
  
  // Navigation sub-menu active
  extendedNavActive: false,
  
  // Initialize the application
  init: function() {
    console.log('Initializing Fitness Tracker App');
    
    // Initialize all app modules
    this.initNavigation();
    this.initDashboard();
    this.initWorkouts();
    this.initNutrition();
    this.initHabits();
    this.initModals();
    
    // Load data from localStorage
    this.loadData();
  },
  
  // Initialize navigation
  initNavigation: function() {
    // Main navbar tabs
    document.querySelectorAll('.navbar-nav .nav-link').forEach(navLink => {
      navLink.addEventListener('click', (e) => {
        e.preventDefault();
        const targetId = e.target.id;
        
        if (targetId === 'dashboard-tab') {
          this.switchTab('dashboard');
        } else if (targetId === 'workouts-tab') {
          this.switchTab('workouts');
        } else if (targetId === 'nutrition-tab') {
          this.switchTab('nutrition');
        } else if (targetId === 'habits-tab') {
          this.switchTab('habits');
        }
      });
    });
    
    // Bottom navigation
    document.querySelectorAll('.bottom-nav .nav-link').forEach(navLink => {
      navLink.addEventListener('click', (e) => {
        e.preventDefault();
        const targetId = e.currentTarget.id;
        
        // Update active state in bottom nav
        document.querySelectorAll('.bottom-nav .nav-link').forEach(link => {
          link.classList.remove('active');
        });
        e.currentTarget.classList.add('active');
        
        // Switch to corresponding tab
        if (targetId === 'nav-dashboard') {
          this.switchTab('dashboard');
        } else if (targetId === 'nav-workouts') {
          this.switchTab('workouts');
        } else if (targetId === 'nav-nutrition') {
          this.switchTab('nutrition');
        } else if (targetId === 'nav-tracking') {
          this.toggleExtendedNav();
        } else if (targetId === 'nav-profile') {
          // Show profile modal
          const profileModal = new bootstrap.Modal(document.getElementById('profileModal'));
          profileModal.show();
        }
      });
    });
    
    // Extended navigation for tracking features
    document.querySelectorAll('.nav-extended .nav-link').forEach(navLink => {
      navLink.addEventListener('click', (e) => {
        e.preventDefault();
        const targetId = e.currentTarget.id;
        
        // Update active state in extended nav
        document.querySelectorAll('.nav-extended .nav-link').forEach(link => {
          link.classList.remove('active');
        });
        e.currentTarget.classList.add('active');
        
        // Switch to corresponding tracking tab
        if (targetId === 'nav-habits') {
          this.switchTab('habits');
        } else if (targetId === 'nav-sleep') {
          this.switchTab('sleep');
        } else if (targetId === 'nav-meditation') {
          this.switchTab('meditation');
        } else if (targetId === 'nav-goals') {
          this.switchTab('goals');
        }
      });
    });
  },
  
  // Toggle extended navigation menu
  toggleExtendedNav: function() {
    const extendedNav = document.querySelector('.nav-extended');
    if (extendedNav) {
      if (this.extendedNavActive) {
        extendedNav.style.display = 'none';
        this.extendedNavActive = false;
      } else {
        extendedNav.style.display = 'flex';
        this.extendedNavActive = true;
      }
    }
  },
  
  // Switch between main content tabs
  switchTab: function(tabName) {
    // Hide all content sections
    document.querySelectorAll('.content-section').forEach(section => {
      section.style.display = 'none';
    });
    
    // Show the selected tab
    const targetTab = document.getElementById(`${tabName}-content`);
    if (targetTab) {
      targetTab.style.display = 'block';
      this.currentTab = tabName;
      
      // Update navbar active state
      document.querySelectorAll('.navbar-nav .nav-link').forEach(link => {
        link.classList.remove('active');
      });
      const navLink = document.getElementById(`${tabName}-tab`);
      if (navLink) {
        navLink.classList.add('active');
      }
      
      // For tracking features, make sure extended nav is visible
      if (['habits', 'sleep', 'meditation', 'goals'].includes(tabName)) {
        const trackingNav = document.getElementById('nav-tracking');
        if (trackingNav && !this.extendedNavActive) {
          this.toggleExtendedNav();
        }
      }
    }
  },
  
  // Initialize dashboard
  initDashboard: function() {
    // Add steps button
    const addStepsBtn = document.getElementById('add-steps-btn');
    if (addStepsBtn) {
      addStepsBtn.addEventListener('click', () => {
        // Prepare steps modal for input
        const stepsInput = document.getElementById('steps-input');
        if (stepsInput) stepsInput.value = '';
      });
    }
    
    // Save steps button
    const saveStepsBtn = document.getElementById('save-steps');
    if (saveStepsBtn) {
      saveStepsBtn.addEventListener('click', () => {
        const stepsInput = document.getElementById('steps-input');
        if (stepsInput && stepsInput.value) {
          const steps = parseInt(stepsInput.value);
          if (!isNaN(steps) && steps > 0) {
            if (typeof tracker !== 'undefined') {
              tracker.addSteps(steps);
              this.updateDashboardStats();
            }
            
            // Close the modal
            const stepsModal = bootstrap.Modal.getInstance(document.getElementById('stepsModal'));
            if (stepsModal) stepsModal.hide();
          }
        }
      });
    }
    
    // Activity logging
    const saveActivityBtn = document.getElementById('save-activity');
    if (saveActivityBtn) {
      saveActivityBtn.addEventListener('click', () => {
        const nameInput = document.getElementById('activity-name');
        const caloriesInput = document.getElementById('activity-calories');
        const durationInput = document.getElementById('activity-duration');
        const typeSelect = document.getElementById('activity-type');
        
        if (nameInput && caloriesInput && durationInput && typeSelect) {
          const name = nameInput.value.trim();
          const calories = parseInt(caloriesInput.value);
          const duration = parseInt(durationInput.value);
          const type = typeSelect.value;
          
          if (name && !isNaN(calories) && !isNaN(duration) && type) {
            if (typeof Activity !== 'undefined' && typeof tracker !== 'undefined') {
              const activity = new Activity(name, calories, duration, type);
              tracker.addActivity(activity);
              this.updateDashboardStats();
              this.renderActivitiesList();
            }
            
            // Clear form and close modal
            nameInput.value = '';
            caloriesInput.value = '';
            durationInput.value = '';
            typeSelect.value = 'running';
            
            const activityModal = bootstrap.Modal.getInstance(document.getElementById('activityModal'));
            if (activityModal) activityModal.hide();
          }
        }
      });
    }
    
    // Initialize progress chart (if Chart.js is loaded)
    if (typeof Chart !== 'undefined') {
      this.initActivityChart();
    }
  },
  
  // Initialize activity chart
  initActivityChart: function() {
    const ctx = document.getElementById('progress-chart');
    if (!ctx) return;
    
    const chartData = {
      labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      datasets: [{
        label: 'Activities',
        data: [1, 2, 0, 3, 1, 2, 4],
        backgroundColor: 'rgba(13, 110, 253, 0.2)',
        borderColor: 'rgba(13, 110, 253, 1)',
        borderWidth: 1
      }]
    };
    
    const chartConfig = {
      type: 'bar',
      data: chartData,
      options: {
        scales: {
          y: {
            beginAtZero: true,
            ticks: {
              stepSize: 1
            }
          }
        },
        plugins: {
          title: {
            display: true,
            text: 'Weekly Activity Count'
          }
        }
      }
    };
    
    const activityChart = new Chart(ctx, chartConfig);
    
    // Toggle between weekly and monthly views
    document.getElementById('weekly-view').addEventListener('click', (e) => {
      e.target.classList.add('active');
      document.getElementById('monthly-view').classList.remove('active');
      
      activityChart.data.labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      activityChart.data.datasets[0].data = [1, 2, 0, 3, 1, 2, 4];
      activityChart.options.plugins.title.text = 'Weekly Activity Count';
      activityChart.update();
    });
    
    document.getElementById('monthly-view').addEventListener('click', (e) => {
      e.target.classList.add('active');
      document.getElementById('weekly-view').classList.remove('active');
      
      activityChart.data.labels = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
      activityChart.data.datasets[0].data = [7, 12, 8, 15];
      activityChart.options.plugins.title.text = 'Monthly Activity Count';
      activityChart.update();
    });
  },
  
  // Update dashboard statistics
  updateDashboardStats: function() {
    // Update only if tracker is defined
    if (typeof tracker !== 'undefined') {
      // Update steps count
      const stepsCount = document.getElementById('steps-count');
      if (stepsCount) {
        stepsCount.textContent = tracker.getTotalSteps().toLocaleString();
      }
      
      // Update calories burned
      const caloriesCount = document.getElementById('calories-count');
      if (caloriesCount) {
        caloriesCount.textContent = tracker.getTotalCalories().toLocaleString();
      }
      
      // Update activities count
      const activitiesCount = document.getElementById('activities-count');
      if (activitiesCount) {
        activitiesCount.textContent = tracker.getActivitiesCount().toString();
      }
      
      // Update activities display
      this.renderActivitiesList();
    }
  },
  
  // Render activities list
  renderActivitiesList: function() {
    const activitiesList = document.getElementById('activities-list');
    const noActivities = document.getElementById('no-activities');
    
    if (!activitiesList || !noActivities) return;
    
    if (typeof tracker !== 'undefined') {
      const activities = tracker.getActivities();
      
      if (activities.length === 0) {
        activitiesList.innerHTML = '';
        noActivities.style.display = 'block';
        return;
      }
      
      noActivities.style.display = 'none';
      activitiesList.innerHTML = '';
      
      activities.forEach(activity => {
        const activityElement = document.createElement('div');
        activityElement.className = 'activity-item d-flex align-items-center';
        
        // Generate icon background color based on activity type
        let iconColor = '#007bff';
        let iconClass = 'bi-activity';
        
        switch (activity.type) {
          case 'running':
            iconColor = '#28a745';
            iconClass = 'bi-lightning';
            break;
          case 'cycling':
            iconColor = '#fd7e14';
            iconClass = 'bi-bicycle';
            break;
          case 'weights':
            iconColor = '#dc3545';
            iconClass = 'bi-trophy';
            break;
          case 'swimming':
            iconColor = '#17a2b8';
            iconClass = 'bi-water';
            break;
        }
        
        activityElement.innerHTML = `
          <div class="activity-icon" style="background-color: ${iconColor}; color: white;">
            <i class="${iconClass}"></i>
          </div>
          <div class="flex-grow-1">
            <h5 class="mb-0">${activity.name}</h5>
            <div class="text-muted small">${activity.getFormattedDate()}</div>
          </div>
          <div class="text-end">
            <div class="fw-bold">${activity.calories} cal</div>
            <div class="text-muted small">${activity.duration} mins</div>
          </div>
        `;
        
        activitiesList.appendChild(activityElement);
      });
    }
  },
  
  // Initialize workouts section
  initWorkouts: function() {
    // Workout plan creation
    const saveWorkoutBtn = document.getElementById('save-workout');
    if (saveWorkoutBtn) {
      saveWorkoutBtn.addEventListener('click', () => {
        const nameInput = document.getElementById('workout-name');
        const typeSelect = document.getElementById('workout-type');
        const daysSelect = document.getElementById('workout-days');
        
        if (nameInput && typeSelect && daysSelect) {
          const name = nameInput.value.trim();
          const type = typeSelect.value;
          const days = Array.from(daysSelect.selectedOptions).map(option => option.value);
          
          if (name && type && days.length > 0) {
            // Create and add workout plan (implementation would depend on your workout model)
            this.addWorkoutPlan({
              name,
              type,
              days,
              exercises: []
            });
            
            // Clear form and close modal
            nameInput.value = '';
            typeSelect.value = 'strength';
            Array.from(daysSelect.options).forEach(option => option.selected = false);
            
            const workoutModal = bootstrap.Modal.getInstance(document.getElementById('workoutModal'));
            if (workoutModal) workoutModal.hide();
          }
        }
      });
    }
  },
  
  // Add a workout plan to the UI
  addWorkoutPlan: function(workout) {
    const workoutList = document.getElementById('workout-list');
    const noWorkoutPlans = document.getElementById('no-workout-plans');
    
    if (!workoutList || !noWorkoutPlans) return;
    
    // Show workout list and hide empty message
    noWorkoutPlans.style.display = 'none';
    
    // Create workout card
    const workoutCard = document.createElement('div');
    workoutCard.className = 'col-md-6 col-lg-4 mb-3';
    
    // Map workout type to icon
    let workoutIcon = 'bi-droplet';
    switch (workout.type) {
      case 'strength':
        workoutIcon = 'bi-trophy';
        break;
      case 'cardio':
        workoutIcon = 'bi-heart-pulse';
        break;
      case 'flexibility':
        workoutIcon = 'bi-person';
        break;
    }
    
    // Format days for display
    const daysDisplay = workout.days.map(day => {
      const dayMap = {
        'mon': 'M',
        'tue': 'T',
        'wed': 'W',
        'thu': 'T',
        'fri': 'F',
        'sat': 'S',
        'sun': 'S'
      };
      return dayMap[day] || day;
    }).join('·');
    
    workoutCard.innerHTML = `
      <div class="card h-100">
        <div class="card-body">
          <div class="d-flex justify-content-between align-items-center mb-3">
            <h5 class="card-title mb-0">${workout.name}</h5>
            <i class="${workoutIcon} fs-4"></i>
          </div>
          <div class="mb-3">
            <span class="badge bg-primary">${workout.type}</span>
            <span class="text-muted ms-2 small">${daysDisplay}</span>
          </div>
          ${workout.exercises.length === 0 ? 
            '<p class="text-muted">No exercises added yet</p>' : 
            `<p>${workout.exercises.length} exercise(s)</p>`
          }
        </div>
        <div class="card-footer bg-transparent">
          <button class="btn btn-sm btn-outline-primary w-100">View Plan</button>
        </div>
      </div>
    `;
    
    workoutList.appendChild(workoutCard);
  },
  
  // Initialize nutrition section
  initNutrition: function() {
    // Meal logging
    const saveMealBtn = document.getElementById('save-meal');
    if (saveMealBtn) {
      saveMealBtn.addEventListener('click', () => {
        const nameInput = document.getElementById('meal-name');
        const caloriesInput = document.getElementById('meal-calories');
        const proteinInput = document.getElementById('meal-protein');
        const carbsInput = document.getElementById('meal-carbs');
        const fatInput = document.getElementById('meal-fat');
        
        if (nameInput && caloriesInput && proteinInput && carbsInput && fatInput) {
          const name = nameInput.value.trim();
          const calories = parseInt(caloriesInput.value);
          const protein = parseInt(proteinInput.value) || 0;
          const carbs = parseInt(carbsInput.value) || 0;
          const fat = parseInt(fatInput.value) || 0;
          
          if (name && !isNaN(calories)) {
            // Add meal (implementation would depend on your nutrition model)
            this.addMeal({
              name,
              calories,
              protein,
              carbs,
              fat,
              date: new Date()
            });
            
            // Clear form and close modal
            nameInput.value = '';
            caloriesInput.value = '';
            proteinInput.value = '';
            carbsInput.value = '';
            fatInput.value = '';
            
            const mealModal = bootstrap.Modal.getInstance(document.getElementById('mealModal'));
            if (mealModal) mealModal.hide();
          }
        }
      });
    }
  },
  
  // Add a meal to the UI
  addMeal: function(meal) {
    const mealList = document.getElementById('meal-list');
    const noMeals = document.getElementById('no-meals');
    
    if (!mealList || !noMeals) return;
    
    // Show meal list and hide empty message
    noMeals.style.display = 'none';
    
    // Format time
    const timeOptions = { hour: 'numeric', minute: '2-digit' };
    const timeString = meal.date.toLocaleTimeString(undefined, timeOptions);
    
    // Create meal element
    const mealElement = document.createElement('div');
    mealElement.className = 'card mb-2';
    
    mealElement.innerHTML = `
      <div class="card-body">
        <div class="d-flex justify-content-between align-items-center">
          <div>
            <h5 class="card-title mb-0">${meal.name}</h5>
            <div class="text-muted small">${timeString}</div>
          </div>
          <div class="text-end">
            <div class="fw-bold">${meal.calories} cal</div>
            <div class="d-flex text-muted small">
              <span class="me-2">P: ${meal.protein}g</span>
              <span class="me-2">C: ${meal.carbs}g</span>
              <span>F: ${meal.fat}g</span>
            </div>
          </div>
        </div>
      </div>
    `;
    
    mealList.appendChild(mealElement);
    
    // Update nutrition summary
    this.updateNutritionSummary(meal);
  },
  
  // Update nutrition summary in UI
  updateNutritionSummary: function(newMeal) {
    // This is a simple implementation - in a real app, you'd store meals and calculate totals
    const todayCalories = document.getElementById('today-calories');
    const proteinPerc = document.getElementById('protein-perc');
    const carbsPerc = document.getElementById('carbs-perc');
    const fatPerc = document.getElementById('fat-perc');
    
    if (todayCalories) {
      const currentCals = parseInt(todayCalories.textContent) || 0;
      todayCalories.textContent = (currentCals + newMeal.calories).toString();
    }
    
    // Calculate and update macros (simplified)
    if (proteinPerc && carbsPerc && fatPerc) {
      // Get current displayed percentages
      const currentProtein = parseInt(proteinPerc.textContent) || 0;
      const currentCarbs = parseInt(carbsPerc.textContent) || 0;
      const currentFat = parseInt(fatPerc.textContent) || 0;
      
      // Assuming 4 cal/g protein, 4 cal/g carbs, 9 cal/g fat
      const totalCalories = newMeal.protein * 4 + newMeal.carbs * 4 + newMeal.fat * 9;
      
      if (totalCalories > 0) {
        const newProteinPerc = Math.round((newMeal.protein * 4 / totalCalories) * 100);
        const newCarbsPerc = Math.round((newMeal.carbs * 4 / totalCalories) * 100);
        const newFatPerc = Math.round((newMeal.fat * 9 / totalCalories) * 100);
        
        // Simple average (not weighted) - just for demonstration
        proteinPerc.textContent = Math.round((currentProtein + newProteinPerc) / 2).toString();
        carbsPerc.textContent = Math.round((currentCarbs + newCarbsPerc) / 2).toString();
        fatPerc.textContent = Math.round((currentFat + newFatPerc) / 2).toString();
        
        // Update progress bars
        const progressBars = document.querySelectorAll('.progress-stacked .progress');
        if (progressBars.length === 3) {
          progressBars[0].style.width = `${proteinPerc.textContent}%`;
          progressBars[1].style.width = `${carbsPerc.textContent}%`;
          progressBars[2].style.width = `${fatPerc.textContent}%`;
        }
      }
    }
  },
  
  // Initialize habits section
  initHabits: function() {
    // Save habit button
    const saveHabitBtn = document.getElementById('save-habit');
    if (saveHabitBtn) {
      saveHabitBtn.addEventListener('click', () => {
        const nameInput = document.getElementById('habit-name');
        const descriptionInput = document.getElementById('habit-description');
        const frequencySelect = document.getElementById('habit-frequency');
        const reminderInput = document.getElementById('habit-reminder');
        const triggerInput = document.getElementById('habit-trigger');
        const alternativeInput = document.getElementById('habit-alternative');
        
        // Get selected habit category
        const categoryRadio = document.querySelector('input[name="habit-type"]:checked');
        
        if (nameInput && descriptionInput && frequencySelect && categoryRadio) {
          const name = nameInput.value.trim();
          const description = descriptionInput.value.trim();
          const frequency = frequencySelect.value;
          const category = categoryRadio.value;
          const trigger = triggerInput ? triggerInput.value.trim() : '';
          const alternative = alternativeInput ? alternativeInput.value.trim() : '';
          const reminderTime = reminderInput ? reminderInput.value : '';
          
          if (name && description) {
            if (typeof BadHabit !== 'undefined' && typeof habitTracker !== 'undefined') {
              const habit = new BadHabit(
                null, // id will be generated
                name,
                description,
                frequency,
                category,
                trigger,
                alternative,
                reminderTime
              );
              
              habitTracker.addHabit(habit);
              this.renderHabitsList();
              this.updateHabitStats();
            }
            
            // Clear form
            nameInput.value = '';
            descriptionInput.value = '';
            frequencySelect.value = 'daily';
            document.getElementById('type-screen').checked = true;
            if (triggerInput) triggerInput.value = '';
            if (alternativeInput) alternativeInput.value = '';
            if (reminderInput) reminderInput.value = '';
            
            // Close modal
            const habitModal = bootstrap.Modal.getInstance(document.getElementById('habitModal'));
            if (habitModal) habitModal.hide();
          }
        }
      });
    }
    
    // Add click handler for habit toggle switches
    document.addEventListener('change', (e) => {
      if (e.target && e.target.id && e.target.id.includes('habit-') && e.target.id.includes('-toggle')) {
        const habitId = e.target.id.replace('habit-', '').replace('-toggle', '');
        const isChecked = e.target.checked;
        
        if (typeof habitTracker !== 'undefined') {
          habitTracker.recordCheckIn(habitId, new Date(), isChecked);
          this.updateHabitStats();
        }
      }
    });
    
    // Initial render
    this.renderHabitsList();
    this.updateHabitStats();
  },
  
  // Render the habits list
  renderHabitsList: function() {
    const habitList = document.getElementById('habit-list');
    const noHabits = document.getElementById('no-habits');
    
    if (!habitList || !noHabits) return;
    
    // Check if habitTracker is available
    if (typeof habitTracker === 'undefined') {
      console.error('habitTracker not defined');
      return;
    }
    
    const habits = habitTracker.getHabits();
    
    if (habits.length === 0) {
      habitList.innerHTML = '';
      noHabits.style.display = 'block';
      return;
    }
    
    noHabits.style.display = 'none';
    habitList.innerHTML = '';
    
    habits.forEach(habit => {
      const daysSince = habit.getDaysSinceStart();
      const habitElement = document.createElement('div');
      habitElement.className = 'card mb-3';
      
      // Check if there's a check-in for today
      const today = new Date();
      const todayStr = habit.formatDateKey(today);
      const todayCheckIn = habit.checkIns.find(checkIn => 
        habit.formatDateKey(checkIn.date) === todayStr
      );
      
      const isCheckedToday = todayCheckIn ? todayCheckIn.success : false;
      
      habitElement.innerHTML = `
        <div class="card-body">
          <div class="d-flex justify-content-between align-items-center">
            <div>
              <h5 class="card-title mb-1">${habit.name}</h5>
              <div class="text-muted small">Trying to quit • Started ${daysSince} days ago</div>
            </div>
            <div class="form-check form-switch">
              <input class="form-check-input" type="checkbox" id="habit-${habit.id}-toggle" ${isCheckedToday ? 'checked' : ''}>
              <label class="form-check-label" for="habit-${habit.id}-toggle">Avoided Today</label>
            </div>
          </div>
          <div class="progress mt-3">
            <div class="progress-bar bg-success" style="width: ${habit.streakData.successRate}%" role="progressbar">${habit.streakData.successRate}% Success Rate</div>
          </div>
        </div>
      `;
      
      habitList.appendChild(habitElement);
    });
  },
  
  // Update habit statistics in the UI
  updateHabitStats: function() {
    if (typeof habitTracker === 'undefined') return;
    
    // Get overall progress
    const progress = habitTracker.getOverallProgress();
    
    // Update streak displays
    const currentStreakEl = document.querySelector('#habits-content .card-title:contains("Quitting Streaks") + div .display-6:nth-child(1)');
    const bestStreakEl = document.querySelector('#habits-content .card-title:contains("Quitting Streaks") + div .display-6:nth-child(2)');
    const daysWithoutEl = document.querySelector('#habits-content .card-title:contains("Quitting Streaks") + div .display-6:nth-child(3)');
    
    if (currentStreakEl) currentStreakEl.textContent = progress.currentStreak.toString();
    if (bestStreakEl) bestStreakEl.textContent = progress.bestStreak.toString();
    if (daysWithoutEl) daysWithoutEl.textContent = progress.daysWithout.toString();
    
    // Update progress bar
    const progressBar = document.querySelector('#habits-content .progress .progress-bar');
    if (progressBar) {
      progressBar.style.width = `${progress.successRate}%`;
      progressBar.setAttribute('aria-valuenow', progress.successRate);
      progressBar.textContent = `${progress.successRate}% Success`;
    }
    
    // Update weekly indicators
    this.updateWeeklyHabitIndicators();
  },
  
  // Update the day indicators for weekly habit progress
  updateWeeklyHabitIndicators: function() {
    if (typeof habitTracker === 'undefined') return;
    
    const habits = habitTracker.getHabits();
    if (habits.length === 0) return;
    
    // For simplicity, we'll use the first habit's weekly progress
    // In a real app, you might want to combine data from all habits
    const habit = habits[0];
    const weeklyProgress = habit.getWeeklyProgress();
    
    // Map day abbreviations
    const dayMap = {
      'Sun': 6,
      'Mon': 0,
      'Tue': 1,
      'Wed': 2,
      'Thu': 3,
      'Fri': 4,
      'Sat': 5
    };
    
    // Get all day indicators
    const dayIndicators = document.querySelectorAll('.habit-day-indicator');
    
    // Reset all indicators
    dayIndicators.forEach(indicator => {
      indicator.classList.remove('completed');
    });
    
    // Update based on progress data
    weeklyProgress.forEach((day, index) => {
      if (day.success === true) {
        const dayIndex = dayMap[day.day];
        if (dayIndex !== undefined && dayIndicators[dayIndex]) {
          dayIndicators[dayIndex].classList.add('completed');
        }
      }
    });
  },
  
  // Initialize all modals
  initModals: function() {
    // Initialize Bootstrap tooltips
    const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]');
    if (tooltipTriggerList.length > 0) {
      [...tooltipTriggerList].map(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl));
    }
  },
  
  // Load data from localStorage
  loadData: function() {
    // This will trigger the loading of fitness tracking data
    if (typeof tracker !== 'undefined') {
      this.updateDashboardStats();
    }
    
    // This will trigger the loading of habit tracking data
    if (typeof habitTracker !== 'undefined') {
      this.renderHabitsList();
      this.updateHabitStats();
    }
  }
};

// Initialize app when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
  app.init();
  
  // Extend jQuery-like functionality for selectors
  if (!document.querySelector.contains) {
    document.querySelector.contains = function(selector) {
      if (typeof selector !== 'string') return null;
      
      // Parse the contains part from the selector
      const matches = selector.match(/:contains\("(.+?)"\)/);
      if (!matches || matches.length < 2) return null;
      
      const searchText = matches[1];
      const baseSelector = selector.replace(/:contains\("(.+?)"\)/, '');
      
      // Find elements matching the base selector
      const elements = document.querySelectorAll(baseSelector);
      
      // Filter to those containing the text
      for (let i = 0; i < elements.length; i++) {
        if (elements[i].textContent.includes(searchText)) {
          return elements[i];
        }
      }
      
      return null;
    };
  }
});