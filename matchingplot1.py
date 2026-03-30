rho     = 1.225       # Air density at sea level (kg/m3)
rho_alt = 0.90        # Air density at 3000m altitude (kg/m3)
g       = 9.81        # Gravitational acceleration (m/s2)

CLmax   = 1.25        # Maximum lift coefficient (NACA 4412)
CD0     = 0.035       # Zero-lift drag coefficient
AR      = 2.2 / 0.33  # Aspect ratio = wingspan / chord = 6.67
e       = 0.8         # Oswald efficiency factor
k       = 1 / (np.pi * AR * e)   # Induced drag factor
LD_max  = 21.0        # Maximum lift-to-drag ratio (from XFLR5)

V_cr    = 15.0        # Cruise speed (m/s)
V_max   = 22.0        # Maximum speed (m/s)
RC      = 2.5         # Rate of climb (m/s)
n_turn  = 1.155       # Load factor at 30 degree bank angle
S_TO    = 12.0        # STOL ground roll distance (m)
RC_ceil = 0.5         # Residual climb rate at ceiling (m/s)

# Takeoff speed
V_stall = 9.85        # Stall speed (m/s)
V_TO    = 1.2 * V_stall   # Takeoff speed = 1.2 x Vstall = 11.82 m/s

# Dynamic pressures
q_cr   = 0.5 * rho * V_cr**2     # Cruise dynamic pressure (Pa)
q_max  = 0.5 * rho * V_max**2    # Max speed dynamic pressure (Pa)
q_ceil = 0.5 * rho_alt * V_cr**2 # Ceiling dynamic pressure (Pa)

# Wing loading range
WS = np.linspace(10, 220, 1000)  # N/m2

# CONSTRAINT EQUATIONS

# 1. Cruise at 15 m/s
TW_cruise  = (q_cr * CD0) / WS + (k / q_cr) * WS

# 2. Climb at 2.5 m/s
TW_climb   = (RC / V_cr) + (q_cr * CD0) / WS + (k / q_cr) * WS

# 3. STOL Takeoff at 12 m (horizontal line - independent of W/S)
TW_takeoff_val = (V_TO**2) / (2 * g * S_TO) + (1 / LD_max)
TW_takeoff     = np.full_like(WS, TW_takeoff_val)

# 4. Maximum speed at 22 m/s
TW_vmax = (q_max * CD0) / WS + (k / q_max) * WS

# 5. Turn performance at 30 degree bank (n = 1.155)
TW_turn = (q_cr * CD0) / WS + (k * n_turn**2 / q_cr) * WS

# 6. Service ceiling at 3000 m
TW_ceil = (RC_ceil / V_cr) + (q_ceil * CD0) / WS + (k / q_ceil) * WS

# Stall limit (vertical line)
WS_stall = 116.4  # N/m2 (from original report)

# DESIGN POINT
# W/S = 75.7 N/m2 (fixed), T/W = 0.70
WS_design = 75.7
TW_design = 0.70

# FEASIBLE REGION
# Above most restrictive lower bound
# Left of stall limit
mask = WS <= WS_stall
WS_feas = WS[mask]
TW_lower_bound = np.maximum(
    np.maximum(TW_climb[mask], TW_takeoff[mask]),
    TW_ceil[mask]
)

# PLOT

fig, ax = plt.subplots(figsize=(13, 8))

# Feasible design region
ax.fill_between(WS_feas, TW_lower_bound, 0.85,
                alpha=0.20, color='green',
                label='Feasible Design Region')

# Constraint curves
ax.plot(WS, TW_cruise,  color='#1f77b4', linewidth=2,
        label='Cruise @ 15 m/s')
ax.plot(WS, TW_climb,   color='#ff7f0e', linewidth=2,
        label='Climb @ 2.5 m/s')
ax.plot(WS, TW_takeoff, color='#2ca02c', linewidth=2.5,
        label=f'STOL Takeoff (S_TO={S_TO}m, T/W={TW_takeoff_val:.2f})')
ax.plot(WS, TW_vmax,    color='#9467bd', linewidth=2,
        label='Max Speed @ 22 m/s')
ax.plot(WS, TW_turn,    color='#8c564b', linewidth=2,
        label='Turn (n=1.155, phi=30 deg)')
ax.plot(WS, TW_ceil,    color='#e377c2', linewidth=2,
        label='Service Ceiling (3000 m)')

# Stall limit vertical line
ax.axvline(x=WS_stall, color='red', linewidth=2.5,
           linestyle='--',
           label=f'Stall Limit (W/S <= {WS_stall} N/m2)')

# Design point
ax.plot(WS_design, TW_design, 'k*', markersize=22, zorder=10,
        label=f'Design Point (W/S={WS_design} N/m2, T/W={TW_design})')

# Annotation for design point
ax.annotate(
    f'  Design Point\n  W/S = {WS_design} N/m2\n  T/W = {TW_design}',
    xy=(WS_design, TW_design),
    xytext=(WS_design + 28, TW_design + 0.06),
    fontsize=9.5,
    arrowprops=dict(arrowstyle='->', color='black', lw=1.8),
    bbox=dict(boxstyle='round,pad=0.4', facecolor='lightyellow',
              edgecolor='black', alpha=0.95)
)

# Dotted guide lines at design point
ax.axvline(x=WS_design, color='gray', linewidth=1.0,
           linestyle=':', alpha=0.7)
ax.axhline(y=TW_design, color='gray', linewidth=1.0,
           linestyle=':', alpha=0.7)

# Axis formatting
ax.set_xlim(10, 220)
ax.set_ylim(0, 0.85)
ax.set_xlabel('Wing Loading W/S (N/m2)', fontsize=12)
ax.set_ylabel('Required Thrust-to-Weight Ratio T/W', fontsize=12)
ax.set_title(
    'Matching Plot for 5.5 kg Fixed-Wing Cargo UAV (STOL)\n'
    'Pulchowk Campus - Mechanical Engineering Final Year Project',
    fontsize=13, fontweight='bold'
)
ax.legend(loc='upper right', fontsize=8.5, framealpha=0.95)
ax.grid(True, linestyle='--', alpha=0.5)
ax.minorticks_on()
ax.grid(True, which='minor', linestyle=':', alpha=0.25)

# Aircraft parameters text box
textstr = (
    'Aircraft Parameters:\n'
    '  MTOW     = 5.5 kg\n'
    '  Wing Area = 0.726 m2\n'
    '  Wingspan  = 2.2 m\n'
    '  Airfoil   = NACA 4412\n'
    '  CLmax = 1.25,  CD0 = 0.035\n'
    '  AR = 6.67,  e = 0.8\n'
    '  L/D max  = 21\n'
    '  Vstall = 9.85 m/s\n'
    '  VTO    = 11.82 m/s\n'
    '  STO    = 12 m (STOL)'
)
props = dict(boxstyle='round', facecolor='lightyellow', alpha=0.85)
ax.text(0.02, 0.97, textstr, transform=ax.transAxes,
        fontsize=8.0, verticalalignment='top', bbox=props)

plt.tight_layout()
plt.savefig('matching_plot_STOL.png', dpi=300, bbox_inches='tight')
plt.show()