# Datos de prueba para la base de datos

-- scripts/seed.sql - Datos de ejemplo para desarrollo

-- Crear tabla de ejemplo
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- Insertar datos de prueba
INSERT INTO users (username, email) VALUES
    ('developer1', 'dev1@example.com'),
    ('developer2', 'dev2@example.com'),
    ('test_user', 'test@example.com')
ON CONFLICT (username) DO NOTHING;

-- Mostrar datos cargados
SELECT '✅ Datos de prueba cargados' as status;
SELECT COUNT(*) as total_users FROM users;