/**
 * API Client with Server-Sent Events support
 *
 * Handles all communication with the Flask backend.
 * Uses SSE for real-time state updates.
 */
class APIClient {
    constructor(baseURL = '/api') {
        this.baseURL = baseURL;
        this.eventSource = null;
        this.onStateUpdate = null;
        this.onConnectionChange = null;
        this.reconnectAttempts = 0;
        this.maxReconnectAttempts = 10;
    }

    /**
     * Start SSE connection for real-time updates
     */
    connectSSE() {
        if (this.eventSource) {
            this.eventSource.close();
        }

        this.eventSource = new EventSource(`${this.baseURL}/events`);

        this.eventSource.onopen = () => {
            console.log('SSE connected');
            this.reconnectAttempts = 0;
            if (this.onConnectionChange) {
                this.onConnectionChange(true);
            }
        };

        this.eventSource.onmessage = (event) => {
            try {
                const data = JSON.parse(event.data);
                if (this.onStateUpdate) {
                    this.onStateUpdate(data);
                }
            } catch (e) {
                console.error('Failed to parse SSE data:', e);
            }
        };

        this.eventSource.onerror = () => {
            console.log('SSE disconnected');
            if (this.onConnectionChange) {
                this.onConnectionChange(false);
            }

            // EventSource auto-reconnects, but track attempts
            this.reconnectAttempts++;
            if (this.reconnectAttempts > this.maxReconnectAttempts) {
                console.log('Max reconnect attempts reached');
                this.eventSource.close();
            }
        };
    }

    /**
     * Close SSE connection
     */
    disconnect() {
        if (this.eventSource) {
            this.eventSource.close();
            this.eventSource = null;
        }
    }

    /**
     * Generic fetch wrapper with error handling
     */
    async request(endpoint, options = {}) {
        const url = `${this.baseURL}${endpoint}`;
        const config = {
            headers: {
                'Content-Type': 'application/json',
            },
            ...options,
        };

        if (config.body && typeof config.body === 'object') {
            config.body = JSON.stringify(config.body);
        }

        try {
            const response = await fetch(url, config);

            if (!response.ok) {
                const error = await response.json().catch(() => ({ error: response.statusText }));
                throw new Error(error.error || `HTTP ${response.status}`);
            }

            return response.json();
        } catch (e) {
            if (e.name === 'TypeError' && e.message === 'Failed to fetch') {
                throw new Error('Unable to connect to server. Is it running?');
            }
            throw e;
        }
    }

    // Convenience methods
    get(endpoint) {
        return this.request(endpoint);
    }

    post(endpoint, data = {}) {
        return this.request(endpoint, { method: 'POST', body: data });
    }

    // State API
    getState() { return this.get('/state'); }
    getStatus() { return this.get('/status'); }

    // Config API
    getConfig() { return this.get('/config'); }
    saveConfig(config) { return this.post('/config', config); }

    // Questions API
    getQuestions() { return this.get('/questions'); }
    submitAnswers(answers) { return this.post('/questions/answer', { answers }); }
    skipQuestions() { return this.post('/questions/skip', {}); }

    // Planning Questions API (new)
    refinePlan(skipped) { return this.post('/actions/refine-plan', { skipped }); }
    openQuestionsFile() { return this.get('/questions/open'); }

    // Action API (new endpoints)
    generatePlan() { return this.post('/actions/generate-plan', {}); }
    executePlan() { return this.post('/actions/execute', {}); }
    continueExecution() { return this.post('/actions/continue', {}); }
    cancel() { return this.post('/actions/cancel', {}); }
    retry() { return this.post('/actions/retry', {}); }
    reset() { return this.post('/actions/reset', {}); }

    // System API
    checkSystem() { return this.get('/claude/check'); }
    openOutput() { return this.get('/output/open'); }
    openPlan() { return this.get('/plan/open'); }
    openReferences() { return this.get('/references/open'); }

    // Reference files
    getReferences() { return this.get('/references'); }
    archiveReferences() { return this.post('/references/archive', {}); }

    // Upload files (special handling for FormData)
    async uploadReferences(files) {
        const formData = new FormData();
        for (const file of files) {
            formData.append('files', file);
        }
        const response = await fetch(`${this.baseURL}/references/upload`, {
            method: 'POST',
            body: formData  // Don't set Content-Type, browser will set it with boundary
        });
        if (!response.ok) {
            const error = await response.json().catch(() => ({ error: response.statusText }));
            throw new Error(error.error || `HTTP ${response.status}`);
        }
        return response.json();
    }

    // Archives
    getArchives() { return this.get('/archive/list'); }
    openArchive() { return this.get('/archive/open'); }

    // Full reset (archive + reset)
    resetProject(projectName) { return this.post('/reset', { projectName }); }
}

// Export singleton
const api = new APIClient();
