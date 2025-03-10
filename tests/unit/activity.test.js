const Activity = require('../../src/models/activity');

describe('Activity Model', () => {
  describe('constructor', () => {
    test('should create an activity with all properties', () => {
      const now = new Date();
      const activity = new Activity('Running', 250, 30, 'running', now);
      
      expect(activity.name).toBe('Running');
      expect(activity.calories).toBe(250);
      expect(activity.duration).toBe(30);
      expect(activity.type).toBe('running');
      expect(activity.date).toBe(now);
    });

    test('should use current date if date is not provided', () => {
      const activity = new Activity('Running', 250, 30, 'running');
      
      expect(activity.date).toBeInstanceOf(Date);
      // The date should be close to now (within 1 second)
      expect(activity.date.getTime()).toBeCloseTo(new Date().getTime(), -3);
    });
  });

  describe('getFormattedDate', () => {
    test('should return a formatted date string', () => {
      const date = new Date(2025, 2, 10); // March 10, 2025
      const activity = new Activity('Running', 250, 30, 'running', date);
      
      // This test assumes en-US locale
      expect(activity.getFormattedDate()).toBe('Mar 10, 2025');
    });
  });

  describe('isValid', () => {
    test('should return true for valid activity', () => {
      const activity = new Activity('Running', 250, 30, 'running');
      expect(activity.isValid()).toBe(true);
    });

    test('should return false if name is empty', () => {
      const activity = new Activity('', 250, 30, 'running');
      expect(activity.isValid()).toBe(false);
    });

    test('should return false if calories is negative', () => {
      const activity = new Activity('Running', -10, 30, 'running');
      expect(activity.isValid()).toBe(false);
    });

    test('should return false if duration is negative', () => {
      const activity = new Activity('Running', 250, -5, 'running');
      expect(activity.isValid()).toBe(false);
    });

    test('should return false if type is invalid', () => {
      const activity = new Activity('Running', 250, 30, 'invalid-type');
      expect(activity.isValid()).toBe(false);
    });
  });
});