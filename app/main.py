"""
Sample Python Flask Application for GitOps Demo
Production-ready microservice with health checks and metrics
"""
from flask import Flask, jsonify, request
import os
import socket
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Application metadata
APP_VERSION = os.getenv('APP_VERSION', '1.0.0')
ENVIRONMENT = os.getenv('ENVIRONMENT', 'development')
HOSTNAME = socket.gethostname()


@app.route('/')
def home():
    """Main application endpoint"""
    return jsonify({
        'service': 'gitops-demo-app',
        'version': APP_VERSION,
        'environment': ENVIRONMENT,
        'hostname': HOSTNAME,
        'timestamp': datetime.utcnow().isoformat(),
        'message': f'Hello from {ENVIRONMENT} environment!'
    })


@app.route('/health')
def health():
    """Health check endpoint for Kubernetes probes"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat()
    }), 200


@app.route('/ready')
def ready():
    """Readiness probe endpoint"""
    # Add any readiness checks here (DB connections, etc.)
    return jsonify({
        'status': 'ready',
        'timestamp': datetime.utcnow().isoformat()
    }), 200


@app.route('/metrics')
def metrics():
    """Basic metrics endpoint"""
    return jsonify({
        'app_version': APP_VERSION,
        'environment': ENVIRONMENT,
        'hostname': HOSTNAME,
        'uptime': 'TODO: implement uptime tracking'
    })


@app.route('/api/info')
def info():
    """Detailed application information"""
    return jsonify({
        'application': {
            'name': 'gitops-demo-app',
            'version': APP_VERSION,
            'environment': ENVIRONMENT
        },
        'runtime': {
            'hostname': HOSTNAME,
            'python_version': os.sys.version
        },
        'request': {
            'method': request.method,
            'path': request.path,
            'remote_addr': request.remote_addr
        }
    })


@app.errorhandler(404)
def not_found(error):
    """Custom 404 handler"""
    return jsonify({
        'error': 'Not Found',
        'message': 'The requested resource does not exist',
        'status': 404
    }), 404


@app.errorhandler(500)
def internal_error(error):
    """Custom 500 handler"""
    logger.error(f'Internal server error: {error}')
    return jsonify({
        'error': 'Internal Server Error',
        'message': 'An unexpected error occurred',
        'status': 500
    }), 500


if __name__ == '__main__':
    port = int(os.getenv('PORT', 8080))
    logger.info(f'Starting application v{APP_VERSION} in {ENVIRONMENT} environment on port {port}')
    app.run(host='0.0.0.0', port=port, debug=(ENVIRONMENT == 'development'))
