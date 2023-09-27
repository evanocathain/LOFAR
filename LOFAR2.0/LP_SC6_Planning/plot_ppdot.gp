set term x11
set ylabel "Period derivative"
set xlabel "Period (sec)"
set logscale xy
set format y "%1.0t{/Symbol \264}10^{%L}"
set format y "10^{%L}"
plot "< head -202 p_pdot | tail -172" u 2:3 pt 5 title "Core (172 PSRs)"
replot "< head -30 p_pdot" u 2:3 pt 5 title "INT (brightest 30 PSRs)"
