import pygame
import numpy as np
import math

WIDTH, HEIGHT = 800, 600
G = 6.67430e-11
DT = 3600  # one hour per simulation step

class Particle:
    def __init__(self, name, position, mass, velocity, color=(255, 255, 255), radius=5):
        self.name = name
        self.position = np.array(position, dtype=float)
        if self.position.shape[0] < 3:
            self.position = np.concatenate([self.position, np.zeros(3 - self.position.shape[0])])
        self.velocity = np.array(velocity, dtype=float)
        if self.velocity.shape[0] < 3:
            self.velocity = np.concatenate([self.velocity, np.zeros(3 - self.velocity.shape[0])])
        self.mass = mass
        self.color = color
        self.radius = radius

    def draw(self, screen):
        x = int(self.position[0] + WIDTH / 2)
        y = int(self.position[1] + HEIGHT / 2)
        pygame.draw.circle(screen, self.color, (x, y), self.radius)


def precompute_accelerations(particles):
    """Precompute initial gravitational accelerations for each particle."""
    N = len(particles)
    acc = [np.zeros(3) for _ in range(N)]
    for i in range(N):
        for j in range(N):
            if i == j:
                continue
            r_vec = particles[j].position - particles[i].position
            dist = np.linalg.norm(r_vec)
            if dist == 0:
                continue
            force_dir = r_vec / dist
            force_mag = G * particles[j].mass / dist ** 2
            acc[i] += force_dir * force_mag
    return acc


def main():
    pygame.init()
    screen = pygame.display.set_mode((WIDTH, HEIGHT))
    clock = pygame.time.Clock()

    particles = [
        Particle("A", [0, 0, 0], 5e10, [0, 0, 0], color=(255, 0, 0), radius=8),
        Particle("B", [100, 0, 0], 5e10, [0, 1, 0], color=(0, 255, 0), radius=8),
        Particle("C", [0, 100, 0], 5e10, [-1, 0, 0], color=(0, 0, 255), radius=8),
    ]

    accelerations = precompute_accelerations(particles)

    running = True
    while running:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False

        screen.fill((0, 0, 0))

        for i, p in enumerate(particles):
            p.velocity += accelerations[i] * DT
            p.position += p.velocity * DT
            p.draw(screen)

        pygame.display.flip()
        clock.tick(60)

    pygame.quit()


if __name__ == "__main__":
    main()
