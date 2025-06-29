import pygame
import numpy as np
import math
import random
from scipy.spatial import KDTree
from numba import jit

# =============================================================================
# Constants and Simulation Parameters
# =============================================================================
PI = math.pi
WIDTH, HEIGHT = 1900, 1000
FPS = 60
DT = 86400
time_speed = 1.0
c = 2.99792458e8            # Speed of light (m/s)
h = 6.62607015e-34          # Planck's constant (J·s)
Lambda = 1.0e-52            # Cosmological constant (m^-2)
alpha = 1/137.0
G_SIM = 6e-11
EPSILON = 1e-2

NUM_RANDOM_PARTICLES = 100
LIGHT_EFFECT_RADIUS = 150

# AU scaling for galaxy systems (used with an extra scaling factor for visibility)
AU_TO_PIXELS = 300 / 4500e6
MASS_SCALE = 1e-27

# =============================================================================
# Global Game States and Modes
# =============================================================================
game_state = "menu"       # "menu" or "running"
mode = "solar"            # "solar" or "galaxy"
creation_mode = False
god_mode = False
help_mode = False
mini_game_mode = None     # Defense mode toggled with G

new_object_type = None
# When entering creation mode, initialize specs with a default velocity and spin.
new_object_specs = {}
preset_colors = [(255,255,255), (255,255,0), (0,0,255), (255,0,0), (80,0,80)]
selected_particle = None

# Galaxy / Solar System parameters
NUM_GALAXIES = 2
SYSTEMS_PER_GALAXY = 9
PLANETS_PER_SYSTEM = 9

alive_population = 1000
defense_score = 0

meteor_spawn_interval = 3000  # milliseconds between meteor spawns
last_meteor_spawn = 0
meteors = []  # List to track meteor particles
defense_level = 1
last_level_up = 0

# =============================================================================
# Predefined Real Solar System (Central System)
# Distances are in pixels (tuned for good visibility).
# =============================================================================
REAL_SOLAR_SYSTEM = [
    {"name": "Sun", "mass": 1.989e30, "radius": 50, "color": (255,255,0), "pos": (WIDTH/2, HEIGHT/2)},
    {"name": "Mercury", "mass": 3.285e23, "radius": 5, "distance": 60, "color": (200,200,200)},
    {"name": "Venus",   "mass": 4.867e24, "radius": 10, "distance": 90, "color": (255,165,0)},
    {"name": "Earth",   "mass": 5.972e24, "radius": 12, "distance": 130, "color": (0,0,255)},
    {"name": "Mars",    "mass": 6.39e23,  "radius": 8,  "distance": 170, "color": (255,0,0)},
    {"name": "Jupiter", "mass": 1.898e27, "radius": 30, "distance": 240, "color": (255,255,255)},
    {"name": "Saturn",  "mass": 5.683e26, "radius": 28, "distance": 300, "color": (255,255,200)},
    {"name": "Uranus",  "mass": 8.681e25, "radius": 20, "distance": 350, "color": (0,255,255)},
    {"name": "Neptune", "mass": 1.024e26, "radius": 18, "distance": 400, "color": (0,0,255)}
]

# =============================================================================
# Pygame Initialization and Screen Setup
# =============================================================================
pygame.init()
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Cosmic Deity: Universe Sandbox")
clock = pygame.time.Clock()
font = pygame.font.SysFont("Arial", 18)

# Camera and zoom settings
camera_x, camera_y = WIDTH/2, HEIGHT/2
zoom = 1.0

particles = []
lights = []
NUM_STARS = 300
stars = [(random.randint(0, WIDTH), random.randint(0, HEIGHT)) for _ in range(NUM_STARS)]

# =============================================================================
# Particle Class (PRU Relational Particle)
# =============================================================================
class Particle:
    def __init__(self, name, position, mass, velocity, charge, color, visual_radius,
                 fixed=False, spin=0, stable=False, p_type="generic"):
        self.name = name
        # Ensure position is 3D: if less than 3 components, pad with 0.
        pos = np.array(position, dtype=np.float64)
        if pos.shape[0] < 3:
            pos = np.concatenate((pos, np.zeros(3 - pos.shape[0])))
        self.position = pos

        # Ensure velocity is 3D: if less than 3 components, pad with 0.
        vel = np.array(velocity, dtype=np.float64)
        if vel.shape[0] < 3:
            vel = np.concatenate((vel, np.zeros(3 - vel.shape[0])))
        self.velocity = vel

        self.mass = mass
        self.charge = charge
        self.color = color
        self.visual_radius = visual_radius
        self.fixed = fixed
        self.size = visual_radius
        self.trail = []
        self.spin = spin
        self.stable = stable
        self.p_type = p_type
        self.spawn_time = pygame.time.get_ticks() if p_type == "meteor" else None

    def draw(self, surface):
        try:
            # Project 3D position to 2D screen (ignoring z, or applying a simple perspective)
            x_screen = int((self.position[0] - camera_x) * zoom + WIDTH / 2)
            y_screen = int((self.position[1] - camera_y) * zoom + HEIGHT / 2)
            pygame.draw.circle(surface, self.color, (x_screen, y_screen),
                               max(1, int(self.size * zoom)))
        except Exception:
            pass


# =============================================================================
# Helper Functions
# =============================================================================
def draw_arrow(surface, start, end, color, width=2):
    pygame.draw.line(surface, color, start, end, width)
    angle = math.atan2(end[1] - start[1], end[0] - start[0])
    arrow_length = 10
    arrow_angle = math.pi / 6
    left_x = end[0] - arrow_length * math.cos(angle - arrow_angle)
    left_y = end[1] - arrow_length * math.sin(angle - arrow_angle)
    right_x = end[0] - arrow_length * math.cos(angle + arrow_angle)
    right_y = end[1] - arrow_length * math.sin(angle + arrow_angle)
    pygame.draw.polygon(surface, color, [(end[0], end[1]), (left_x, left_y), (right_x, right_y)])

@jit(nopython=True)
def compute_force(pos, neighbor_pos, neighbor_mass, G_val, eps):
    total = np.zeros(2)
    for k in range(neighbor_pos.shape[0]):
        diff0 = neighbor_pos[k, 0] - pos[0]
        diff1 = neighbor_pos[k, 1] - pos[1]
        dist = math.sqrt(diff0 * diff0 + diff1 * diff1) + eps
        total[0] += G_val * neighbor_mass[k] * diff0 / (dist ** 3)
        total[1] += G_val * neighbor_mass[k] * diff1 / (dist ** 3)
    return total




# =============================================================================
# 3D Compute Force Function (JIT-compiled)
# =============================================================================
@jit(nopython=True)
def compute_force_3D(pos, neighbor_pos, neighbor_mass, G_val, eps):
    """
    Computes the net gravitational force on an object at position 'pos' (3D)
    from neighbors (each given in neighbor_pos, a 2D array with shape (n, 3)).
    Uses a softened Newtonian formula.
    """
    total = np.zeros(3)
    for k in range(neighbor_pos.shape[0]):
        # Compute difference vector in 3D
        diff = neighbor_pos[k] - pos
        dist = math.sqrt(diff[0] * diff[0] + diff[1] * diff[1] + diff[2] * diff[2]) + eps
        # Add contribution from neighbor k
        total[0] += G_val * neighbor_mass[k] * diff[0] / (dist ** 3)
        total[1] += G_val * neighbor_mass[k] * diff[1] / (dist ** 3)
        total[2] += G_val * neighbor_mass[k] * diff[2] / (dist ** 3)
    return total



def update_gravitational_constant():
    """
    Dynamically updates G_SIM using the emergent formula:

        G_SIM = (c * h) / (Lambda * alpha * sqrt(N_eff))

    Here, N_eff is the effective particle count.
    We set N_eff = N_sim * scale_factor, where scale_factor is chosen to represent
    the real density of particles.
    """
    global G_SIM, particles
    N_sim = len(particles)
    scale_factor = 1e76  # Choose this factor so that N_eff approximates the real universe (e.g., ~10^80)
    N_eff = N_sim * scale_factor
    if N_eff == 0:
        N_eff = 1  # Avoid division by zero
    sqrt_N = np.sqrt(N_eff)
    G_SIM = (c * h) / (Lambda * alpha * sqrt_N)
    # Optional: print debugging info
    # print(f"N_sim = {N_sim}, N_eff = {N_eff:.3e}, sqrt(N_eff) = {sqrt_N:.3e}, G_SIM = {G_SIM:.3e}")


# =============================================================================
# Updated Universe Update Function in 3D
# =============================================================================
def update_universe():
    """
    Updates the simulation universe in 3D using a two-step Velocity Verlet-like integration:
    1. Update gravitational constant G_SIM based on the current particle count.
    2. Compute accelerations via KDTree neighbor searches (in full 3D).
    3. Perform a half-step velocity update, update positions, rebuild KDTree,
       recompute accelerations, then update velocities fully.
    4. Update trails for visualization.
    """
    global particles, G_SIM, DT, time_speed

    # Update dynamic gravitational constant first
    update_gravitational_constant()

    N = len(particles)
    if N == 0:
        return

    # Build positions array in 3D
    positions = np.array([p.position for p in particles])
    tree = KDTree(positions)
    acc = np.zeros((N, 3))

    # First acceleration pass using up to 5 nearest neighbors.
    for i, p in enumerate(particles):
        if p.fixed:
            continue
        k = 5 if N >= 5 else N
        neighbors_idx = tree.query(positions[i], k=k)[1]
        if i not in neighbors_idx:
            neighbors_idx = np.append(neighbors_idx, i)
        neighbor_list = [particles[j] for j in neighbors_idx if j != i]
        if len(neighbor_list) == 0:
            continue
        neighbor_positions = np.array([n.position for n in neighbor_list])
        neighbor_masses = np.array([n.mass for n in neighbor_list])
        force = compute_force_3D(p.position, neighbor_positions, neighbor_masses, G_SIM, EPSILON)
        acc[i] = force / p.mass

    # Half-step velocity update.
    for i, p in enumerate(particles):
        if not p.fixed:
            p.velocity += 0.5 * acc[i] * DT * time_speed

    # Update positions using the half-step velocities.
    for i, p in enumerate(particles):
        if not p.fixed:
            p.position += p.velocity * DT * time_speed

    # Rebuild positions array and KDTree after moving.
    positions = np.array([p.position for p in particles])
    tree = KDTree(positions)
    new_acc = np.zeros((N, 3))

    # Second acceleration pass.
    for i, p in enumerate(particles):
        if p.fixed:
            continue
        neighbors_idx = tree.query(positions[i], k=5)[1]
        if i not in neighbors_idx:
            neighbors_idx = np.append(neighbors_idx, i)
        neighbor_list = [particles[j] for j in neighbors_idx if j != i]
        if len(neighbor_list) == 0:
            continue
        neighbor_positions = np.array([n.position for n in neighbor_list])
        neighbor_masses = np.array([n.mass for n in neighbor_list])
        force = compute_force_3D(p.position, neighbor_positions, neighbor_masses, G_SIM, EPSILON)
        new_acc[i] = force / p.mass

    # Full velocity update and trail update.
    for i, p in enumerate(particles):
        if not p.fixed:
            p.velocity += 0.5 * new_acc[i] * DT * time_speed
            p.trail.append(tuple(p.position))
            if len(p.trail) > 20:
                p.trail.pop(0)


def handle_collisions():
    global particles, alive_population, defense_score
    merged_particles = []
    to_remove = set()
    N = len(particles)
    MASS_CAP = 1e31  # Example maximum mass for an object
    for i in range(N):
        for j in range(i + 1, N):
            p1 = particles[i]
            p2 = particles[j]
            # Skip if both are stable, etc.
            if p1.stable and p2.stable:
                continue
            # Check for collision based on visual radii
            if np.linalg.norm(p1.position - p2.position) < (p1.visual_radius + p2.visual_radius) * 0.5:
                new_mass = p1.mass + p2.mass
                # Only merge if new mass is below cap, otherwise, "absorb" the smaller into the larger
                if new_mass < MASS_CAP:
                    new_velocity = (p1.mass * p1.velocity + p2.mass * p2.velocity) / new_mass
                    new_color = tuple(min(255, int((p1.color[k] * p1.mass + p2.color[k] * p2.mass) / new_mass))
                                      for k in range(3))
                    new_radius = (p1.visual_radius ** 3 + p2.visual_radius ** 3) ** (1 / 3)
                    merged_particles.append(Particle(p1.name + "+" + p2.name,
                                                     (p1.mass * p1.position + p2.mass * p2.position) / new_mass,
                                                     new_mass, new_velocity, 0, new_color, new_radius))
                    to_remove.add(i)
                    to_remove.add(j)
                else:
                    # Absorb: larger object gains the mass of the smaller, but no new object is created
                    if p1.mass > p2.mass:
                        p1.mass = new_mass
                        p1.velocity = (p1.mass * p1.velocity + p2.mass * p2.velocity) / new_mass
                        to_remove.add(j)
                    else:
                        p2.mass = new_mass
                        p2.velocity = (p1.mass * p1.velocity + p2.mass * p2.velocity) / new_mass
                        to_remove.add(i)
    if to_remove:
        particles[:] = [particles[i] for i in range(N) if i not in to_remove]
        particles.extend(merged_particles)


# =============================================================================
# Object Creation Functions
# =============================================================================
def create_particle_from_dict(specs, stable=False, p_type="user", fixed=False):
    name = specs["name"]
    color = specs["color"]
    pos = np.array(specs["pos"], dtype=np.float64)
    velocity = specs.get("velocity", np.array([0, 0]))
    mass = specs["mass"] * MASS_SCALE
    visual_radius = specs["radius"]
    spin = specs.get("spin", 0)
    particles.append(Particle(name, pos, mass, velocity, 0, color, visual_radius, fixed, spin, stable, p_type))

# -----------------------------------------------------------------------------
# Solar System and Galaxy Creation Functions
# -----------------------------------------------------------------------------

# =============================================================================
# Updated Function: create_real_solar_system
# =============================================================================
def create_real_solar_system():
    # Create the Sun (ensure its position is 3D)
    for body in REAL_SOLAR_SYSTEM:
        if body["name"] == "Sun":
            specs = body.copy()
            # Convert 2D pos to 3D: add a 0 for z.
            pos_2d = np.array(specs["pos"], dtype=np.float64)
            specs["pos"] = np.concatenate((pos_2d, [0]))
            create_particle_from_dict(specs, stable=True, p_type="system", fixed=True)

    # Create orbiting bodies (planets)
    sun = next((b for b in REAL_SOLAR_SYSTEM if b["name"] == "Sun"), None)
    if sun is None:
        return
    sun_pos_2d = np.array(sun["pos"], dtype=np.float64)
    sun_pos = np.concatenate((sun_pos_2d, [0]))
    sun_mass = sun["mass"]

    for body in REAL_SOLAR_SYSTEM:
        if body["name"] != "Sun":
            angle = random.uniform(0, 2 * PI)
            distance = body["distance"]
            # Create a 3D position; z can be 0 or a small random offset if desired.
            pos_2d = np.array([sun_pos[0] + distance * math.cos(angle),
                               sun_pos[1] + distance * math.sin(angle)], dtype=np.float64)
            pos = np.concatenate((pos_2d, [0]))  # 3D position
            v_mag = math.sqrt(G_SIM * sun_mass * MASS_SCALE / (distance + EPSILON))
            velocity_2d = np.array([-math.sin(angle), math.cos(angle)]) * v_mag
            velocity = np.concatenate((velocity_2d, [0]))
            specs = {
                "name": body["name"],
                "mass": body["mass"],
                "radius": body["radius"],
                "color": body["color"],
                "pos": pos,
                "velocity": velocity,
                "spin": 0
            }
            create_particle_from_dict(specs, stable=True, p_type="system")

def create_solar_system(center, sys_velocity, num_planets=PLANETS_PER_SYSTEM):
    # Use a simple scaling factor; here we assume distances are given in pixels.
    solar_distance_factor = 1.0  # Direct pixel values for orbit radii.
    sun_color = (255, 255, 0)
    sun_mass = 1.989e30  # SI units
    sun_radius = 50

    # Ensure center and sys_velocity are 3D vectors.
    center = np.array(center, dtype=np.float64)
    if center.shape[0] < 3:
        center = np.concatenate((center, [0]))
    sys_velocity = np.array(sys_velocity, dtype=np.float64)
    if sys_velocity.shape[0] < 3:
        sys_velocity = np.concatenate((sys_velocity, [0]))

    sun = {
        "name": f"Sun-{random.randint(0,1000)}",
        "mass": sun_mass,
        "radius": sun_radius,
        "color": sun_color,
        "pos": center,
        "velocity": sys_velocity,
        "spin": 0
    }
    create_particle_from_dict(sun, stable=True, p_type="system")

    # Use fixed orbital distances for stability (e.g., evenly spaced).
    base_distances = np.linspace(200, 600, num_planets)  # in pixels
    for i in range(num_planets):
        distance = base_distances[i] * solar_distance_factor
        angle = random.uniform(0, 2 * PI)
        pos_2d = np.array([center[0] + distance * math.cos(angle),
                           center[1] + distance * math.sin(angle)], dtype=np.float64)
        pos = np.concatenate((pos_2d, [0]))  # 3D position; z = 0 initially.
        r = np.linalg.norm(pos - center)
        # Circular orbit: v = sqrt(G * M_sun / r)
        # Use the effective gravitational constant G_SIM.
        v_mag = math.sqrt(G_SIM * sun_mass * MASS_SCALE / (r + EPSILON))
        vel_2d = np.array([-math.sin(angle), math.cos(angle)]) * v_mag
        velocity = np.concatenate((vel_2d, [0])) + sys_velocity
        planet = {
            "name": f"Planet-{random.randint(0,1000)}",
            "mass": random.uniform(1e24, 5e24),
            "radius": random.uniform(5,15),
            "color": random.choice(preset_colors),
            "pos": pos,
            "velocity": velocity * 15,
            "spin": 0
        }
        create_particle_from_dict(planet, stable=True, p_type="system")



def create_galaxy(galaxy_center, num_systems=SYSTEMS_PER_GALAXY, galaxy_radius=500e6):
    for i in range(num_systems):
        angle = random.uniform(0, 2 * PI)
        distance = random.uniform(0.2, 1.0) * galaxy_radius * AU_TO_PIXELS
        sys_center = np.array([galaxy_center[0] + distance * math.cos(angle),
                               galaxy_center[1] + distance * math.sin(angle)], dtype=np.float64)
        r = np.linalg.norm(sys_center - np.array(galaxy_center))
        v_mag = math.sqrt(G_SIM * 1e40 / (r + EPSILON))
        sys_velocity = np.array([-math.sin(angle), math.cos(angle)]) * v_mag
        create_solar_system(sys_center, sys_velocity)

def create_galaxies():
    for i in range(NUM_GALAXIES):
        galaxy_center = (random.uniform(WIDTH * 0.2, WIDTH * 0.8),
                         random.uniform(HEIGHT * 0.2, HEIGHT * 0.8))
        create_galaxy(galaxy_center)

def create_random_particle(position):
    pos = np.array(position, dtype=np.float64)
    # Pad position to 3D if necessary:
    if pos.shape[0] < 3:
        pos = np.concatenate((pos, np.zeros(3 - pos.shape[0])))
    sun = next((p for p in particles if p.name.startswith("Sun")), None)
    if sun:
        r_vec = pos - sun.position
        r = np.linalg.norm(r_vec)
        if r > EPSILON:
            angle = math.atan2(r_vec[1], r_vec[0])
            v_mag = math.sqrt(G_SIM * sun.mass / (r + EPSILON))
            velocity = np.array([-math.sin(angle), math.cos(angle)])
            # Pad velocity to 3D:
            velocity = np.concatenate((velocity, [0]))
            velocity *= v_mag
        else:
            velocity = np.array([0, 0, 0])
    else:
        velocity = np.array([random.uniform(-0.5, 0.5), random.uniform(-0.5, 0.5)])
        velocity = np.concatenate((velocity, [0]))
    mass = random.uniform(50, 1000) * MASS_SCALE
    color = (random.randint(100, 255), random.randint(100, 255), random.randint(100, 255))
    visual_radius = random.uniform(5, 20)
    spec = {
        "name": "Custom",
        "mass": mass / MASS_SCALE,
        "radius": visual_radius,
        "color": color,
        "pos": pos,
        "velocity": velocity,
        "spin": 0
    }
    create_particle_from_dict(spec)


def create_random_light(position):
    lights.append(position)

# =============================================================================
# Meteor (Defense) Functions
# =============================================================================
def spawn_meteor():
    edge = random.choice(["top", "bottom", "left", "right"])
    if edge == "top":
        pos = np.array([random.uniform(0, WIDTH), 0, 0])
    elif edge == "bottom":
        pos = np.array([random.uniform(0, WIDTH), HEIGHT, 0])
    elif edge == "left":
        pos = np.array([0, random.uniform(0, HEIGHT), 0])
    else:
        pos = np.array([WIDTH, random.uniform(0, HEIGHT), 0])
    systems = [p for p in particles if p.stable and p.p_type == "system"]
    if systems:
        target = random.choice(systems)
        direction = target.position - pos
        norm = np.linalg.norm(direction)
        direction = direction / norm if norm > EPSILON else np.array([0, 0, 0])
    else:
        direction = np.array([0, 0, 0])
    speed = random.uniform(0, 0.00005) + (defense_level * 0.00005)
    velocity = direction * speed
    mass = random.uniform(1e22, 1e23)
    radius = random.uniform(60, 100)  # Larger meteor radius for visibility.
    color = (255, 100, 0)
    meteor = Particle("Meteor", pos, mass, velocity, 0, color, radius,
                        fixed=False, spin=0, stable=False, p_type="meteor")
    meteor.spawn_time = pygame.time.get_ticks()
    particles.append(meteor)
    meteors.append(meteor)

# =============================================================================
# Drawing Functions
# =============================================================================
def draw_earth_environment(surface, current_time):
    for y in range(0, int(HEIGHT * 0.75)):
        ratio = y / (HEIGHT * 0.75)
        sky_color = (int(10 + 20 * ratio), int(10 + 30 * ratio), int(40 + 60 * ratio))
        pygame.draw.line(surface, sky_color, (0, y), (WIDTH, y))
    for y in range(int(HEIGHT * 0.75), HEIGHT):
        ratio = (y - HEIGHT * 0.75) / (HEIGHT * 0.25)
        ground_color = (int(30 + 50 * ratio), int(100 + 80 * ratio), int(30 + 50 * ratio))
        pygame.draw.line(surface, ground_color, (0, y), (WIDTH, y))
    sun_angle = (current_time - 6) / 12 * PI
    sun_orbit_radius = 300
    sun_x = WIDTH / 2 + sun_orbit_radius * math.cos(sun_angle - PI)
    sun_y = HEIGHT * 0.75 - sun_orbit_radius * math.sin(sun_angle - PI)
    brightness = max(0, min(255, int(255 * math.sin(sun_angle))))
    sun_color = (brightness, brightness, 0)
    pygame.draw.circle(surface, sun_color, (int(sun_x), int(sun_y)), 40)

def draw_god_mode_ui(surface):
    panel_width, panel_height = 400, 200
    panel_surface = pygame.Surface((panel_width, panel_height), pygame.SRCALPHA)
    panel_surface.fill((0, 0, 0, 200))
    instructions = [
        "GOD MODE: Omnipotence enabled!",
        "1: Create full solar system at mouse",
        "2: Remove nearest particle",
        "3: Cosmic storm (random impulse)",
        "4: Increase gravity (G_SIM)",
        "5: Decrease gravity (G_SIM)",
        "6: Randomize universe",
        "7: Epic collision burst",
        "F1: Exit God Mode"
    ]
    y = 10
    for line in instructions:
        text = font.render(line, True, (255, 255, 255))
        panel_surface.blit(text, (10, y))
        y += 15
    surface.blit(panel_surface, (WIDTH - panel_width - 10, 10))

def draw_help_ui(surface):
    panel_width, panel_height = 500, 260
    panel_surface = pygame.Surface((panel_width, panel_height), pygame.SRCALPHA)
    panel_surface.fill((0, 0, 0, 220))
    instructions = [
        "HELP - KEY BINDINGS:",
        "",
        "General:",
        "  SPACE: Pause/Resume simulation",
        "  M: Toggle solar/galaxy view",
        "  R: Restart simulation (menu)",
        "",
        "Creation Mode:",
        "  N: Create planet, U: Create sun, B: Create black hole",
        "  Arrows: Adjust mass & radius continuously",
        "  I/K: Increase/Decrease velocity",
        "  J/L: Rotate velocity",
        "  O/P: Adjust spin",
        "  C: Cycle color, ENTER: Create, ESC: Cancel",
        "",
        "Defense Mode:",
        "  G: Toggle defense mode (meteors spawn)",
        "",
        "God Mode (F1 to toggle):",
        "  1: Create solar system at mouse",
        "  2: Remove nearest particle",
        "  3: Cosmic storm",
        "  4/5: Increase/Decrease gravity",
        "  6: Randomize universe",
        "  7: Epic collision burst",
        "",
        "H: Toggle this help screen"
    ]
    y = 10
    for line in instructions:
        text = font.render(line, True, (255,255,255))
        panel_surface.blit(text, (10, y))
        y += 15
    surface.blit(panel_surface, (10, 10))

def draw_creation_ui(surface):
    panel_width, panel_height = 350, 140
    panel_surface = pygame.Surface((panel_width, panel_height), pygame.SRCALPHA)
    panel_surface.fill((0, 0, 0, 180))
    instructions = [
        f"Creation Mode: {new_object_type.upper()}",
        f"Mass: {new_object_specs.get('mass', 0):.2e}",
        f"Radius: {new_object_specs.get('radius', 0):.1f}",
        f"Velocity: {new_object_specs.get('velocity', np.array([0,0]))}",
        f"Spin: {new_object_specs.get('spin', 0):.2f}",
        "",
        "Hold Arrows, I/K, J/L, O/P",
        "C: Cycle color | ENTER: Create | ESC: Cancel"
    ]
    y_offset = 10
    for line in instructions:
        text_surf = font.render(line, True, (255,255,255))
        panel_surface.blit(text_surf, (10, y_offset))
        y_offset += 14
    surface.blit(panel_surface, (10, HEIGHT - panel_height - 10))

def draw_overlays(surface, simulation_time):
    info_text = f"Time: {simulation_time:.1f}s | Mode: {mode} | Particles: {len(particles)} | DT: {DT:.3e}"
    info_text += f" | TimeSpeed: {time_speed:.2f}"
    overlay = font.render(info_text, True, (255,255,255))
    surface.blit(overlay, (10, HEIGHT - 30))
    pop_text = f"Alive: {alive_population}  Score: {defense_score}  Level: {defense_level}"
    pop_overlay = font.render(pop_text, True, (0,255,0))
    surface.blit(pop_overlay, (10, 30))
    if mini_game_mode == "defense":
        mode_text = "DEFENSE MODE ACTIVE"
        mode_overlay = font.render(mode_text, True, (255,0,0))
        surface.blit(mode_overlay, (10, 50))

def draw_menu(surface):
    surface.fill((0, 0, 0))
    title = font.render("Cosmic Deity Universe Sandbox", True, (255,255,0))
    prompt = font.render("Press S to Start, Q to Quit, R to Restart", True, (255,255,255))
    help_prompt = font.render("Press H for Help", True, (255,255,255))
    surface.blit(title, (WIDTH//2 - title.get_width()//2, HEIGHT//2 - 60))
    surface.blit(prompt, (WIDTH//2 - prompt.get_width()//2, HEIGHT//2))
    surface.blit(help_prompt, (WIDTH//2 - help_prompt.get_width()//2, HEIGHT//2 + 40))

# =============================================================================
# Update Creation Mode Keys (Continuous Adjustments)
# =============================================================================
def update_creation_mode_keys():
    keys = pygame.key.get_pressed()
    if creation_mode:
        if keys[pygame.K_UP]:
            new_object_specs["mass"] *= 1.005
        if keys[pygame.K_DOWN]:
            new_object_specs["mass"] /= 1.005
        if keys[pygame.K_RIGHT]:
            new_object_specs["radius"] += 0.1
        if keys[pygame.K_LEFT]:
            new_object_specs["radius"] = max(1, new_object_specs["radius"] - 0.1)
        if keys[pygame.K_i]:
            new_object_specs["velocity"] *= 1.005
        if keys[pygame.K_k]:
            new_object_specs["velocity"] *= 0.995
        if keys[pygame.K_j]:
            angle = math.atan2(new_object_specs["velocity"][1], new_object_specs["velocity"][0])
            angle += math.radians(1)
            mag = np.linalg.norm(new_object_specs["velocity"])
            new_object_specs["velocity"] = np.array([math.cos(angle) * mag, math.sin(angle) * mag])
        if keys[pygame.K_l]:
            angle = math.atan2(new_object_specs["velocity"][1], new_object_specs["velocity"][0])
            angle -= math.radians(1)
            mag = np.linalg.norm(new_object_specs["velocity"])
            new_object_specs["velocity"] = np.array([math.cos(angle) * mag, math.sin(angle) * mag])
        if keys[pygame.K_o]:
            new_object_specs["spin"] += 0.005
        if keys[pygame.K_p]:
            new_object_specs["spin"] -= 0.005

# =============================================================================
# Restart Simulation (Reset Globals and Reinitialize)
# =============================================================================
def reset_simulation():
    global particles, lights, alive_population, defense_score, meteor_spawn_interval, defense_level
    global last_meteor_spawn, last_level_up, camera_x, camera_y, zoom, mode, new_object_specs, new_object_type, god_mode, mini_game_mode, G_SIM
    particles = []
    lights = []
    alive_population = 1000
    defense_score = 0
    meteor_spawn_interval = 3000
    defense_level = 1
    last_meteor_spawn = pygame.time.get_ticks()
    last_level_up = pygame.time.get_ticks()
    camera_x, camera_y = WIDTH/2, HEIGHT/2
    zoom = 1.0
    mode = "solar"
    new_object_specs = {}
    new_object_type = None
    god_mode = False
    mini_game_mode = None
    G_SIM = 6e-11
    create_real_solar_system()
    create_galaxies()
    for _ in range(NUM_RANDOM_PARTICLES):
        pos = np.array([random.uniform(0, WIDTH), random.uniform(0, HEIGHT)], dtype=np.float64)
        mass = random.uniform(50, 1000) * MASS_SCALE
        velocity = np.array([random.uniform(-0.5, 0.5), random.uniform(-0.5, 0.5)])
        color = (random.randint(100,255), random.randint(100,255), random.randint(100,255))
        visual_radius = random.uniform(3,8)
        particles.append(Particle("Asteroid", pos, mass, velocity, 0, color, visual_radius))

# =============================================================================
# Main Game Loop
# =============================================================================
def main():
    global camera_x, camera_y, zoom, DT, time_speed, mode, creation_mode, new_object_type, new_object_specs
    global selected_particle, mini_game_mode, last_meteor_spawn, alive_population, defense_score, defense_level
    global last_level_up, god_mode, help_mode, game_state, G_SIM, meteor_spawn_interval

    reset_simulation()
    simulation_time = 0.0
    time_of_day = 12.0
    paused = False
    running = True

    # Main loop
    while running:
        # --- Menu State ---
        if game_state == "menu":
            draw_menu(screen)
            pygame.display.flip()
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_s:
                        reset_simulation()
                        game_state = "running"
                    elif event.key == pygame.K_q:
                        running = False
                    elif event.key == pygame.K_h:
                        help_mode = not help_mode
                        if help_mode:
                            draw_help_ui(screen)
                            pygame.display.flip()
                            pygame.time.wait(3000)
            clock.tick(FPS)
            continue

        # --- Running Simulation ---
        cosmic_surface = pygame.Surface((WIDTH, HEIGHT))
        cosmic_surface.fill((0, 0, 0))
        for star in stars:
            pygame.draw.circle(cosmic_surface, (255,255,255), star, 1)

        if not paused and not creation_mode:
            update_universe()
            simulation_time += DT * time_speed
            handle_collisions()
            if mode == "solar":
                time_of_day = (time_of_day + 0.01 * time_speed * DT) % 24
            if alive_population < 100000:
                alive_population += 1

        for p in particles:
            p.draw(cosmic_surface)
        for light in lights:
            lx = int((light[0] - camera_x) * zoom + WIDTH / 2)
            ly = int((light[1] - camera_y) * zoom + HEIGHT / 2)
            pygame.draw.circle(cosmic_surface, (255,255,100), (lx, ly), 6)

        if mode == "solar":
            screen.fill((0, 0, 0))
            draw_earth_environment(screen, time_of_day)
            sky_rect = pygame.Rect(0, 0, WIDTH, int(HEIGHT * 0.75))
            cosmic_part = cosmic_surface.subsurface(sky_rect)
            screen.blit(cosmic_part, (0, 0))
        else:
            screen.blit(cosmic_surface, (0, 0))

        if mini_game_mode == "defense":
            current_ticks = pygame.time.get_ticks()
            if current_ticks - last_meteor_spawn > meteor_spawn_interval:
                spawn_meteor()
                last_meteor_spawn = current_ticks
            if current_ticks - last_level_up > 30000:
                defense_level += 1
                meteor_spawn_interval = max(1000, meteor_spawn_interval - 200)
                last_level_up = current_ticks
            for meteor in meteors[:]:
                if pygame.time.get_ticks() - meteor.spawn_time >= 5000:
                    if meteor in particles:
                        particles.remove(meteor)
                    meteors.remove(meteor)

        if god_mode:
            draw_god_mode_ui(screen)
        if help_mode:
            draw_help_ui(screen)
        if creation_mode:
            mx, my = pygame.mouse.get_pos()
            world_pos = np.array([(mx - WIDTH/2)/zoom + camera_x, (my - HEIGHT/2)/zoom + camera_y])
            if "velocity" in new_object_specs and np.linalg.norm(new_object_specs["velocity"]) > 0:
                arrow_scale = 50
                arrow_end_world = world_pos + new_object_specs["velocity"] * arrow_scale
                arrow_end_screen = (int((arrow_end_world[0]-camera_x)*zoom+WIDTH/2),
                                    int((arrow_end_world[1]-camera_y)*zoom+HEIGHT/2))
                draw_arrow(screen, (mx, my), arrow_end_screen, (255,255,255))
            draw_creation_ui(screen)

        dynamic_vels = [np.linalg.norm(p.velocity) for p in particles if not p.fixed]
        avg_vel = np.mean(dynamic_vels) if dynamic_vels else 0
        info_text = f"Time: {simulation_time:.1f}s | Mode: {mode} | Particles: {len(particles)} | DT: {DT:.3e}"
        info_text += f" | TimeSpeed: {time_speed:.2f}"
        overlay = font.render(info_text, True, (255,255,255))
        screen.blit(overlay, (10, HEIGHT - 30))
        draw_overlays(screen, simulation_time)

        pygame.display.flip()
        clock.tick(FPS)
        update_creation_mode_keys()

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False

            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_h:
                    help_mode = not help_mode
                    continue

                if event.key == pygame.K_r:
                    game_state = "menu"
                    continue

                if event.key == pygame.K_F1:
                    god_mode = not god_mode
                    if god_mode:
                        creation_mode = False
                        mini_game_mode = None
                        help_mode = False
                    continue

                if god_mode:
                    if event.key == pygame.K_1:
                        mx, my = pygame.mouse.get_pos()
                        pos = np.array([(mx - WIDTH/2)/zoom + camera_x, (my - HEIGHT/2)/zoom + camera_y])
                        create_solar_system(pos, (0,0))
                    elif event.key == pygame.K_2:
                        mx, my = pygame.mouse.get_pos()

                        # Convert screen coordinates to world coordinates
                        world_pos = np.array([(mx - WIDTH / 2) / zoom + camera_x, (my - HEIGHT / 2) / zoom + camera_y,
                                              0.0])  # Ensure 3D compatibility

                        if particles:
                            # Find the closest particle to the mouse click
                            closest = min(particles, key=lambda p: np.linalg.norm(p.position - world_pos))

                            # Remove from both lists to avoid lingering meteors
                            if closest in particles:
                                particles.remove(closest)
                            if closest in meteors:
                                meteors.remove(closest)
                    elif event.key == pygame.K_3:
                        for p in particles:
                            impulse = np.array([random.uniform(-5,5), random.uniform(-5,5),  random.uniform(-5,5)])
                            p.velocity += impulse
                    elif event.key == pygame.K_4:
                        G_SIM *= 1.1
                    elif event.key == pygame.K_5:
                        G_SIM /= 1.1
                    elif event.key == pygame.K_6:
                        for p in particles:
                            # Generate 3D positions: random x, y, and z (for z, you can choose a range appropriate for your simulation)
                            p.position = np.array([
                                random.uniform(0, WIDTH),
                                random.uniform(0, HEIGHT),
                                random.uniform(-HEIGHT / 2, HEIGHT / 2)
                            ], dtype=np.float64)
                            # Generate 3D velocity
                            p.velocity = np.array([
                                random.uniform(-1, 1),
                                random.uniform(-1, 1),
                                random.uniform(-1, 1)
                            ], dtype=np.float64)
                    elif event.key == pygame.K_7:
                        mx, my = pygame.mouse.get_pos()
                        pos = np.array([(mx - WIDTH/2)/zoom + camera_x, (my - HEIGHT/2)/zoom + camera_y])
                        for i in range(20):
                            offset = np.array([random.uniform(-20,20), random.uniform(-20,20)])
                            p_spec = {
                                "name": f"Burst-{i}",
                                "mass": random.uniform(1e22,1e23),
                                "radius": random.uniform(5,10),
                                "color": random.choice(preset_colors),
                                "pos": pos + offset,
                                "velocity": np.array([random.uniform(-3,3), random.uniform(-3,3)]),
                                "spin": 0
                            }
                            create_particle_from_dict(p_spec)
                    continue

                if creation_mode:
                    if event.key == pygame.K_c:
                        current = new_object_specs["color"]
                        idx = preset_colors.index(current) if current in preset_colors else 0
                        new_object_specs["color"] = preset_colors[(idx+1) % len(preset_colors)]
                    elif event.key == pygame.K_RETURN:
                        mx, my = pygame.mouse.get_pos()
                        world_x = (mx - WIDTH/2)/zoom + camera_x
                        world_y = (my - HEIGHT/2)/zoom + camera_y
                        pos = np.array([world_x, world_y], dtype=np.float64)
                        ref = next((p for p in particles if p.stable and p.name.startswith("Sun")), None)
                        if new_object_type == "planet" and ref is not None:
                            if np.linalg.norm(new_object_specs["velocity"]) < 1e-10:
                                r = np.linalg.norm(pos - ref.position)
                                v_mag = math.sqrt(G_SIM * ref.mass / (r + EPSILON))
                                angle = math.atan2(pos[1] - ref.position[1], pos[0] - ref.position[0])
                                velocity = np.array([-math.sin(angle), math.cos(angle)]) * v_mag
                            else:
                                velocity = new_object_specs["velocity"]
                        else:
                            velocity = new_object_specs.get("velocity", np.array([0,0]))
                        new_obj = {
                            "name": f"{new_object_type.capitalize()}-{len(particles)}",
                            "mass": new_object_specs["mass"],
                            "radius": new_object_specs["radius"],
                            "color": new_object_specs["color"],
                            "pos": pos,
                            "velocity": velocity,
                            "spin": new_object_specs["spin"]
                        }
                        create_particle_from_dict(new_obj)
                        creation_mode = False
                        new_object_type = None
                        new_object_specs = {}
                    elif event.key == pygame.K_ESCAPE:
                        creation_mode = False
                        new_object_type = None
                        new_object_specs = {}
                else:
                    if event.key == pygame.K_SPACE:
                        paused = not paused
                    elif event.key in (pygame.K_PLUS, pygame.K_KP_PLUS):
                        DT *= 1.1
                    elif event.key in (pygame.K_MINUS, pygame.K_KP_MINUS):
                        DT /= 1.1
                    elif event.key == pygame.K_m:
                        mode = "galaxy" if mode=="solar" else "solar"
                    elif event.key == pygame.K_n:  # Planet
                        creation_mode = True
                        new_object_type = "planet"
                        new_object_specs = {
                            "mass": 5.972e24,
                            "radius": 10,
                            "color": (255, 255, 255),
                            "velocity": np.array([random.uniform(-0.001, 0.001), random.uniform(-0.001, 0.001)]),
                            # Random velocity
                            "spin": random.uniform(-0.05, 0.05)  # Random spin speed
                        }
                    elif event.key == pygame.K_u:
                        creation_mode = True
                        new_object_type = "sun"
                        new_object_specs = {"mass": 1.989e30, "radius": 50, "color": (255,255,0),
                                            "velocity": np.array([0.0, 0.0]), "spin": 0.0}
                    elif event.key == pygame.K_b:
                        creation_mode = True
                        new_object_type = "black hole"
                        new_object_specs = {"mass": 1e31, "radius": 12, "color": (80,0,80),
                                            "velocity": np.array([0.0, 0.0]), "spin": 0.0}
                    elif event.key == pygame.K_g:
                        if mini_game_mode == "defense":
                            mini_game_mode = None
                        else:
                            mini_game_mode = "defense"
                            defense_score = 0

            elif event.type == pygame.MOUSEBUTTONDOWN:
                if not creation_mode:
                    if mini_game_mode == "defense" and event.button == 1:
                        click_pos = np.array([event.pos[0], event.pos[1], 0.0])  # Ensure 3D compatibility

                        for p in particles[:]:  # Iterate over a copy of the list to avoid modification issues
                            if p.p_type == "meteor" and np.linalg.norm(p.position - click_pos) < p.visual_radius:
                                defense_score += 10

                                # Remove the meteor from both lists safely
                                if p in particles:
                                    particles.remove(p)
                                if p in meteors:
                                    meteors.remove(p)
                                break  # Stop after removing one to avoid iteration issues

                    else:
                        if event.button == 2:
                            mx, my = pygame.mouse.get_pos()
                            world_x = (mx - WIDTH / 2) / zoom + camera_x
                            world_y = (my - HEIGHT / 2) / zoom + camera_y
                            world_z = 0  # Add a default z-coordinate (adjust if needed)

                            click_pos = np.array([world_x, world_y, world_z])  # Now it's 3D

                            for p in particles:
                                if np.linalg.norm(p.position - click_pos) < p.visual_radius:
                                    selected_particle = p
                                    break

                        elif event.button == 1:
                            create_random_particle([(event.pos[0]-WIDTH/2)/zoom + camera_x,
                                                    (event.pos[1]-HEIGHT/2)/zoom + camera_y])
                        elif event.button == 3:
                            create_random_light([(event.pos[0]-WIDTH/2)/zoom + camera_x,
                                                 (event.pos[1]-HEIGHT/2)/zoom + camera_y])
            elif event.type == pygame.MOUSEWHEEL:
                zoom *= 1.1 if event.y > 0 else 0.9

        keys = pygame.key.get_pressed()
        if keys[pygame.K_w]:
            camera_y -= 10/zoom
        if keys[pygame.K_s]:
            camera_y += 10/zoom
        if keys[pygame.K_a]:
            camera_x -= 10/zoom
        if keys[pygame.K_d]:
            camera_x += 10/zoom

    pygame.quit()

if __name__ == '__main__':
    main()
