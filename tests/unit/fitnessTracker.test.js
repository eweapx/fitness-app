const FitnessTracker = require('../../src/services/fitnessTracker');
const Activity = require('../../src/models/activity');

describe('FitnessTracker Service', () => {
  let tracker;
  let activity;

  beforeEach(() => {
    tracker = new FitnessTracker();
    activity = new Activity('Running', 250, 30, 'running', new Date());
  });

  describe('constructor', () => {
    test('should initialize with empty values', () => {
      expect(tracker.activities).toEqual([]);
      expect(tracker.caloriesBurned).toBe(0);
      expect(tracker.stepsCount).toBe(0);
      expect(tracker.activitiesLogged).toBe(0);
    });
  });

  describe('addActivity', () => {
    test('should add a valid activity', () => {
      const result = tracker.addActivity(activity);
      
      expect(result).toBe(true);
      expect(tracker.activities).toContain(activity);
      expect(tracker.caloriesBurned).toBe(250);
      expect(tracker.activitiesLogged).toBe(1);
    });

    test('should not add an invalid activity', () => {
      const invalidActivity = new Activity('', -5, 0, 'invalid');
      const result = tracker.addActivity(invalidActivity);
      
      expect(result).toBe(false);
      expect(tracker.activities).not.toContain(invalidActivity);
      expect(tracker.caloriesBurned).toBe(0);
      expect(tracker.activitiesLogged).toBe(0);
    });

    test('should not add a non-Activity object', () => {
      const nonActivity = { name: 'Running', calories: 250, duration: 30, type: 'running' };
      const result = tracker.addActivity(nonActivity);
      
      expect(result).toBe(false);
      expect(tracker.activities).not.toContain(nonActivity);
      expect(tracker.caloriesBurned).toBe(0);
      expect(tracker.activitiesLogged).toBe(0);
    });
  });

  describe('getActivities', () => {
    test('should return a copy of the activities array', () => {
      tracker.addActivity(activity);
      
      const activities = tracker.getActivities();
      expect(activities).toEqual([activity]);
      
      // Modifying the returned array should not affect the original
      activities.pop();
      expect(tracker.activities).toEqual([activity]);
    });
  });

  describe('getTotalCalories', () => {
    test('should return the total calories burned', () => {
      tracker.addActivity(activity);
      tracker.addActivity(new Activity('Cycling', 150, 20, 'cycling'));
      
      expect(tracker.getTotalCalories()).toBe(400);
    });
  });

  describe('getTotalSteps', () => {
    test('should return the total steps', () => {
      tracker.addSteps(5000);
      
      expect(tracker.getTotalSteps()).toBe(5000);
    });
  });

  describe('addSteps', () => {
    test('should add steps with valid value', () => {
      const result = tracker.addSteps(5000);
      
      expect(result).toBe(true);
      expect(tracker.stepsCount).toBe(5000);
    });

    test('should not add steps with invalid value', () => {
      const result = tracker.addSteps(-100);
      
      expect(result).toBe(false);
      expect(tracker.stepsCount).toBe(0);
    });
  });

  describe('getActivitiesCount', () => {
    test('should return the number of activities logged', () => {
      tracker.addActivity(activity);
      tracker.addActivity(new Activity('Cycling', 150, 20, 'cycling'));
      
      expect(tracker.getActivitiesCount()).toBe(2);
    });
  });

  describe('reset', () => {
    test('should reset all values', () => {
      tracker.addActivity(activity);
      tracker.addSteps(5000);
      
      tracker.reset();
      
      expect(tracker.activities).toEqual([]);
      expect(tracker.caloriesBurned).toBe(0);
      expect(tracker.stepsCount).toBe(0);
      expect(tracker.activitiesLogged).toBe(0);
    });
  });
});