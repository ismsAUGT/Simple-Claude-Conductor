/**
 * Main Alpine.js application for Simple Claude Conductor
 *
 * Provides reactive UI state management with SSE-driven updates.
 */
function conductorApp() {
    return {
        // Connection state
        connected: true,
        loading: false,
        lastUpdateTime: null,
        secondsSinceUpdate: 0,

        // Application state (from server)
        state: {
            state: 'reset',
            phase: 0,
            total_phases: 0,
            phase_name: null,
            process_id: null,
            error: null,
            activity: 'Ready to start'
        },

        // Configuration
        config: {
            projectName: '',
            projectDescription: '',
            defaultModel: 'sonnet',
            allowPlanningQuestions: true
        },
        configExpanded: true,

        // Reference files
        referenceFiles: [],
        noReferenceFiles: false,
        isDragging: false,

        // Questions
        questions: [],

        // System status
        system: {
            installed: false,
            email: null,
            version: null
        },

        // Stage definitions for progress indicator
        stages: [
            { id: 'reset', label: 'Start' },
            { id: 'configured', label: 'Configure' },
            { id: 'planning', label: 'Plan' },
            { id: 'executing', label: 'Execute' },
            { id: 'complete', label: 'Complete' }
        ],

        /**
         * Initialize the application
         */
        async init() {
            // Load initial state
            await this.loadState();
            await this.loadConfig();
            await this.checkSystem();
            await this.loadReferenceFiles();

            // Connect to SSE for real-time updates
            api.onStateUpdate = (data) => this.handleStateUpdate(data);
            api.onConnectionChange = (connected) => this.connected = connected;
            api.connectSSE();

            // Start heartbeat timer (updates every second)
            this.lastUpdateTime = Date.now();
            setInterval(() => {
                this.secondsSinceUpdate = Math.floor((Date.now() - this.lastUpdateTime) / 1000);
            }, 1000);
        },

        /**
         * Handle state update from SSE
         */
        handleStateUpdate(data) {
            // Merge server state with local state
            this.state = { ...this.state, ...data };

            // Reset heartbeat timer
            this.lastUpdateTime = Date.now();
            this.secondsSinceUpdate = 0;

            // Auto-load questions when in questions state
            if (this.state.state === 'questions' && this.questions.length === 0) {
                this.loadQuestions();
            }

            // Auto-collapse config when complete
            if (this.state.state === 'complete') {
                this.configExpanded = false;
            }
        },

        /**
         * Load current state from server
         */
        async loadState() {
            try {
                const state = await api.getState();
                this.state = { ...this.state, ...state };
            } catch (e) {
                console.error('Failed to load state:', e);
            }
        },

        /**
         * Load configuration
         */
        async loadConfig() {
            try {
                const config = await api.getConfig();
                if (config.projectName || config.project?.name) {
                    this.config = {
                        projectName: config.projectName || config.project?.name || '',
                        projectDescription: config.projectDescription || config.project?.description || '',
                        defaultModel: config.defaultModel || config.execution?.default_model || 'sonnet',
                        allowPlanningQuestions: config.allowPlanningQuestions !== undefined ? config.allowPlanningQuestions : true
                    };
                    this.configExpanded = false; // Collapse if already configured
                }
            } catch (e) {
                console.error('Failed to load config:', e);
            }
        },

        /**
         * Save configuration
         */
        async saveConfig() {
            this.loading = true;
            try {
                await api.saveConfig(this.config);
                this.configExpanded = false;
                await this.loadState();
            } catch (e) {
                alert('Failed to save configuration: ' + e.message);
            } finally {
                this.loading = false;
            }
        },

        /**
         * Check system status
         */
        async checkSystem() {
            try {
                this.system = await api.checkSystem();
            } catch (e) {
                console.error('Failed to check system:', e);
            }
        },

        /**
         * Load questions
         */
        async loadQuestions() {
            try {
                const data = await api.getQuestions();
                this.questions = data.questions || [];
            } catch (e) {
                console.error('Failed to load questions:', e);
            }
        },

        /**
         * Perform the primary action based on current state
         */
        async performAction() {
            this.loading = true;
            try {
                switch (this.state.state) {
                    case 'reset':
                    case 'configured':
                        // Auto-save config before generating plan
                        await api.saveConfig(this.config);
                        await api.generatePlan();
                        break;
                    case 'planned':
                        await api.executePlan();
                        break;
                    case 'questions':
                        await this.submitAnswers();
                        return; // submitAnswers handles loading state
                    case 'complete':
                        await this.resetProject();
                        return;
                    case 'error':
                        await api.retry();
                        break;
                }
            } catch (e) {
                alert('Action failed: ' + e.message);
            } finally {
                this.loading = false;
            }
        },

        /**
         * Submit question answers
         */
        async submitAnswers() {
            this.loading = true;
            try {
                const answers = {};
                this.questions.forEach(q => {
                    answers[q.number] = q.answer || '(No answer provided)';
                });
                await api.submitAnswers(answers);
                await api.continueExecution();
                this.questions = [];
            } catch (e) {
                alert('Failed to submit answers: ' + e.message);
            } finally {
                this.loading = false;
            }
        },

        /**
         * Skip questions
         */
        async skipQuestions() {
            if (!confirm('Skip answering questions? Claude will make assumptions.')) {
                return;
            }
            this.loading = true;
            try {
                await api.skipQuestions();
                await api.continueExecution();
                this.questions = [];
            } catch (e) {
                alert('Failed to skip questions: ' + e.message);
            } finally {
                this.loading = false;
            }
        },

        /**
         * Open questions file in default editor
         */
        async openQuestionsFile() {
            try {
                await api.openQuestionsFile();
            } catch (e) {
                alert('Failed to open questions file: ' + e.message);
            }
        },

        /**
         * Continue after answering planning questions
         */
        async continueAfterQuestions(skipped) {
            if (skipped && !confirm('Skip answering questions? Claude will use their best judgment.')) {
                return;
            }
            this.loading = true;
            try {
                await api.refinePlan(skipped);
            } catch (e) {
                alert('Failed to refine plan: ' + e.message);
            } finally {
                this.loading = false;
            }
        },

        /**
         * Cancel current operation
         */
        async cancel() {
            if (!confirm('Cancel the current operation?')) {
                return;
            }
            this.loading = true;
            try {
                await api.cancel();
            } catch (e) {
                alert('Failed to cancel: ' + e.message);
            } finally {
                this.loading = false;
            }
        },

        /**
         * Reset project
         */
        async resetProject() {
            if (!confirm('Start a new project? Current work will be archived.')) {
                return;
            }
            this.loading = true;
            try {
                await api.resetProject(this.config.projectName || 'project');
                this.configExpanded = true;
                this.config = {
                    projectName: '',
                    projectDescription: '',
                    defaultModel: 'sonnet'
                };
                this.noReferenceFiles = false;
                await this.loadReferenceFiles();
            } catch (e) {
                alert('Failed to reset: ' + e.message);
            } finally {
                this.loading = false;
            }
        },

        /**
         * Retry after error
         */
        async retry() {
            this.loading = true;
            try {
                await api.retry();
            } catch (e) {
                alert('Failed to retry: ' + e.message);
            } finally {
                this.loading = false;
            }
        },

        /**
         * Refresh state manually
         */
        async refresh() {
            await this.loadState();
            await this.checkSystem();
        },

        /**
         * Open output folder
         */
        async openOutput() {
            try {
                await api.openOutput();
            } catch (e) {
                alert('Failed to open output folder: ' + e.message);
            }
        },

        /**
         * Open task-plan.md in default editor
         */
        async openPlan() {
            try {
                await api.openPlan();
            } catch (e) {
                alert('Failed to open plan: ' + e.message);
            }
        },

        /**
         * Open references folder
         */
        async openReferences() {
            try {
                await api.openReferences();
            } catch (e) {
                alert('Failed to open references folder: ' + e.message);
            }
        },

        /**
         * Open archives folder
         */
        async openArchive() {
            try {
                await api.openArchive();
            } catch (e) {
                alert('Failed to open archives folder: ' + e.message);
            }
        },

        /**
         * Load reference files list
         */
        async loadReferenceFiles() {
            try {
                const files = await api.getReferences();
                this.referenceFiles = files || [];
            } catch (e) {
                console.error('Failed to load reference files:', e);
            }
        },

        /**
         * Archive reference files (move to archive folder)
         */
        async archiveReferenceFiles() {
            if (this.referenceFiles.length === 0) {
                alert('No reference files to archive.');
                return;
            }
            if (!confirm('Archive all reference files? They will be moved to the archive folder.')) {
                return;
            }
            this.loading = true;
            try {
                await api.archiveReferences();
                await this.loadReferenceFiles();
            } catch (e) {
                alert('Failed to archive reference files: ' + e.message);
            } finally {
                this.loading = false;
            }
        },

        /**
         * Handle file drop
         */
        async handleFileDrop(event) {
            event.preventDefault();
            this.isDragging = false;

            const files = event.dataTransfer?.files;
            if (!files || files.length === 0) return;

            await this.uploadFiles(files);
        },

        /**
         * Handle file input change
         */
        async handleFileInput(event) {
            const files = event.target.files;
            if (!files || files.length === 0) return;

            await this.uploadFiles(files);
            // Reset input so same file can be selected again
            event.target.value = '';
        },

        /**
         * Upload files to reference folder
         */
        async uploadFiles(files) {
            this.loading = true;
            try {
                await api.uploadReferences(files);
                await this.loadReferenceFiles();
                this.noReferenceFiles = false;
            } catch (e) {
                alert('Failed to upload files: ' + e.message);
            } finally {
                this.loading = false;
            }
        },

        /**
         * Handle drag over
         */
        handleDragOver(event) {
            event.preventDefault();
            this.isDragging = true;
        },

        /**
         * Handle drag leave
         */
        handleDragLeave(event) {
            event.preventDefault();
            this.isDragging = false;
        },

        // Computed properties

        get statusDotClass() {
            const classes = {
                'complete': 'status-dot--success',
                'executing': 'status-dot--warning',
                'planning': 'status-dot--warning',
                'planned': 'status-dot--success',
                'questions': 'status-dot--warning',
                'error': 'status-dot--error'
            };
            return classes[this.state.state] || 'status-dot--neutral';
        },

        get statusTitle() {
            const titles = {
                'reset': 'Ready to Start',
                'configured': 'Ready to Generate Plan',
                'planning': 'Generating Plan...',
                'plan_questions': 'Questions About Your Project',
                'planned': 'Plan Ready',
                'executing': 'Executing...',
                'questions': 'Questions Pending',
                'complete': 'Project Complete!',
                'error': 'Error Occurred'
            };
            return titles[this.state.state] || 'Unknown State';
        },

        get actionButtonText() {
            if (this.loading) return 'Working...';
            const texts = {
                'reset': 'Generate Plan',
                'configured': 'Generate Plan',
                'planning': 'Planning...',
                'planned': 'Execute Plan',
                'executing': 'Executing...',
                'questions': 'Submit Answers',
                'complete': 'Start New Project',
                'error': 'Retry'
            };
            return texts[this.state.state] || 'Action';
        },

        get canPerformAction() {
            if (this.loading) return false;
            // Can't act during auto-transition states
            if (['planning', 'executing'].includes(this.state.state)) return false;

            // For generate plan, require config and reference files (or explicit "no files" checkbox)
            if (['reset', 'configured'].includes(this.state.state)) {
                const hasConfig = this.config.projectName.trim() && this.config.projectDescription.trim();
                const hasRefFiles = this.referenceFiles.length > 0 || this.noReferenceFiles;
                return hasConfig && hasRefFiles;
            }

            return true;
        },

        get canCancel() {
            return ['planning', 'executing'].includes(this.state.state);
        },

        get canReset() {
            // Can reset from any state except during active operations or already reset
            if (this.loading) return false;
            if (['planning', 'executing'].includes(this.state.state)) return false;
            if (this.state.state === 'reset') return false;
            return true;
        },

        get showConfig() {
            return ['reset', 'configured', 'planned', 'complete'].includes(this.state.state);
        },

        get showPlanQuestions() {
            return this.state.state === 'plan_questions';
        },

        get showHeartbeat() {
            // Show heartbeat during active states
            return ['planning', 'executing'].includes(this.state.state);
        },

        get heartbeatText() {
            if (this.secondsSinceUpdate < 2) {
                return 'Connected - receiving updates';
            } else if (this.secondsSinceUpdate < 10) {
                return `Last update: ${this.secondsSinceUpdate}s ago`;
            } else {
                return `Last update: ${this.secondsSinceUpdate}s ago (still working...)`;
            }
        },

        get progressPercent() {
            if (this.state.total_phases === 0) return 0;
            return Math.round((this.state.phase / this.state.total_phases) * 100);
        },

        get phaseLabel() {
            if (this.state.total_phases === 0) return 'No phases';
            const name = this.state.phase_name || '';
            if (name) {
                return `Phase ${this.state.phase} of ${this.state.total_phases}: ${name}`;
            }
            return `Phase ${this.state.phase} of ${this.state.total_phases}`;
        },

        /**
         * Check if a stage is complete
         */
        isStageComplete(stageId) {
            const order = ['reset', 'configured', 'planning', 'planned', 'executing', 'complete'];
            const currentIndex = order.indexOf(this.state.state);
            const stageIndex = order.indexOf(stageId);

            // Special cases
            if (this.state.state === 'error') return false;
            if (this.state.state === 'questions') {
                // In questions state, executing is active, not complete
                return stageIndex < order.indexOf('executing');
            }

            return stageIndex < currentIndex;
        },

        /**
         * Check if a stage is active
         */
        isStageActive(stageId) {
            const stateToStage = {
                'reset': 'reset',
                'configured': 'configured',
                'planning': 'planning',
                'planned': 'planning',
                'executing': 'executing',
                'questions': 'executing',
                'complete': 'complete',
                'error': null
            };
            return stateToStage[this.state.state] === stageId;
        }
    };
}
