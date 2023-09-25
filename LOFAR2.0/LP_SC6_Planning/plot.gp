set term x11

set ylabel "Number of pulsars"
set xlabel "Cumulative Tobs per epoch (hours)"
#set title "LOFAR Core - All"
set arrow from 60,0 to 60,225 nohead lt 1 lw 3
set arrow from 48,0 to 48,225 nohead lt 1 lw 3
set arrow from 24,0 to 24,225 nohead lt 1 lw 3
set key top left box
set logscale x
set mytics 2
set grid
plot [1:120][0:225]"plot_300_core" u 5:1 w histe title "5mins Core", "plot_600_core" u 5:1 wi histe title "10mins Core"
replot "plot_300_int" u 5:1 wi histe title "5mins INT", "plot_600_int" u 5:1 wi histe title "10mins INT"

