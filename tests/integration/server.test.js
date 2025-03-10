const request = require('supertest');
const app = require('../../server');
const path = require('path');
const fs = require('fs');

describe('Express Server', () => {
  describe('GET /', () => {
    test('should serve the index.html page', async () => {
      const response = await request(app).get('/');
      
      expect(response.status).toBe(200);
      expect(response.headers['content-type']).toMatch(/text\/html/);
      // Check if the response contains expected HTML content
      expect(response.text).toContain('Fuel Fitness');
    });
  });

  describe('GET /api/health', () => {
    test('should return a healthy status', async () => {
      const response = await request(app).get('/api/health');
      
      expect(response.status).toBe(200);
      expect(response.headers['content-type']).toMatch(/application\/json/);
      expect(response.body).toEqual({ status: 'healthy' });
    });
  });

  describe('Static files', () => {
    test('should serve static files', async () => {
      // Create a temporary file for testing
      const testFilePath = path.join(__dirname, '../../test-static.txt');
      fs.writeFileSync(testFilePath, 'test content');
      
      try {
        const response = await request(app).get('/test-static.txt');
        
        expect(response.status).toBe(200);
        expect(response.text).toBe('test content');
      } finally {
        // Clean up test file
        fs.unlinkSync(testFilePath);
      }
    });
  });

  describe('404 handling', () => {
    test('should return 404 for non-existent routes', async () => {
      const response = await request(app).get('/non-existent-path');
      
      expect(response.status).toBe(404);
    });
  });
});