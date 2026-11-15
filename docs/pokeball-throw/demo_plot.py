"""Optional plotting dependency: matplotlib. Physics CLI uses only stdlib."""
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from physics import launch,trajectory

out=Path(__file__).resolve().parent/'evidence'
state=launch((0,3),(0,1,0),(0,1,4))
fig,axes=plt.subplots(1,2,figsize=(10,4.3),layout='constrained')
for spin,color in [(-.8,'#3b82f6'),(0,'#64748b'),(.8,'#ed8c35')]:
    rows=list(trajectory(state,spin,duration=1,dt=.002))
    axes[0].plot([r[3] for r in rows],[r[1] for r in rows],label=f'Release spin {spin:+.1f}',color=color,lw=2)
    axes[1].plot([r[3] for r in rows],[r[2] for r in rows],color=color,lw=2)
axes[0].set(xlabel='Forward distance z (Unity units)',ylabel='Lateral distance x',title='Top view: sign changes lateral acceleration')
axes[1].set(xlabel='Forward distance z (Unity units)',ylabel='Height y',title='Side view: gravity + small spin lift')
for ax in axes:
    ax.grid(alpha=.2);ax.scatter([4],[0 if ax is axes[0] else 1],marker='x',color='#a21caf',label='Target position')
axes[0].legend(fontsize=8)
fig.suptitle('Reconstructed free flight — illustrative geometry, no collision simulation',fontsize=12)
fig.savefig(out/'trajectory-comparison.png',dpi=170)
fig.savefig(out/'trajectory-comparison.svg')
