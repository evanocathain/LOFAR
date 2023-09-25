#!/bin/csh

# 
# A quick script to plan for Science Case 6 of the 
# Pulsar Monitoring LOFAR 2.0 Large Proposal for Science Case 6
#
# EFK Sep 2023
#

# Print Usage
if ($#argv == 0 ) then
  echo "Usage: csh plan.csh [dec_min] [gb_min] [tobs_min] [core/int]"
  # Above should 'just work' but do a csh -f in case it doesn't
  goto death
endif

# Read in command line arguments
set dec_min  = $argv[1]
set sure = y
if ( $dec_min < -7 ) then
  echo "The LOFAR superterp is at latitude 52.9deg. This will result in"
  echo "an elevation below 30deg. Are you sure [y/n]?"
  set sure = $<
  if ( $sure == "n" ) then
    echo "Ok. Exiting."
    goto death
  else if ( $sure == "y" ) then
    echo "Ok. Pressing on."
  else
    echo "Confused. Exiting"
    goto death
  endif
endif
set gb_min   = $argv[2]
set Tobs_min = $argv[3]        # Whatever is here it gets over-ridden for MSPs to be 20 mins.
set array    = $argv[4]
if ( $array == "core" ) then
  set Nstations = 24           # Just the core
else if ( $array == "int" ) then
  set Nstations = 4            # 1 international station == 4 core stations in terms of gain
else
  echo "Confused. Exiting"
  goto death
endif

# What PSRCAT version is being used
set psrcat_version = `psrcat -v | grep "Catalogue version number" | awk '{print $NF}'`
echo "Using PSRCAT version" $psrcat_version
# Try not to use a very old PSRCAT
# PSRCAT v1.60 --- 2702 pulsars 
# PSRCAT v1.69 --- 3359 pulsars

# Set some LOFAR parameters
set lat_lofar    = 52.9      # This is basically the superterp latitude
set snr_min      = 30.0
set Nperiods_min = 1040.0    # Want to have at least 1024 periods for nice FFTs!

#
# Flux_density = SNR * fac1 * fac2 * (gain*Tsys)/(sqrt(2*BW*Tobs))
#
# Take Tobs = Nperiods_min*p0 OR as specified by input cmd arg
# Take Flux_density as S_150 (natively in mJy) from PSRCAT
# Take BW as 90 MHz (so 105 to 195 MHz basically)
# Take Tsys from code. For first answer use Tgal = 54.8K *(408 MHz/150 MHz)^(2.75) = 858 K
# Take fac1 = cos^2(zenith)       # degradation factor, due to projection effects.
# Take fac2 = coherency factor    # degradation factor, due to imperfect coherent summation of stations
# 
# SNR = S_150*sqrt(2*90*10^6*1040*p0)/(fac1*fac2*gain*(858))

# Filter PSRCAT for the dec and gb limits and those that have a S_150 flux density measurement
alias psrcatdog 'psrcat -o short -nohead -nonumber'
psrcatdog -c "name rajd decjd gl gb p0 dm s80 s150" | sort -gr -k9 | awk -v lat_lofar=$lat_lofar -v dec_min=$dec_min -v gb_min=$gb_min '{if ($3<lat_lofar) zenith_angle=lat_lofar-$3; if ($3>=lat_lofar) zenith_angle=$3-lat_lofar; if ($9!="*" && $3>dec_min && ($5>gb_min || $5<-gb_min)) print $1,$6,$7,$9,cos(zenith_angle*3.14159/180.0)^2}' > PSRs_p0_dm_s150_fac1

# Put some header lines in output file
echo "150-MHz Tobs and SNR, to get SNR>="$snr_min" AND (SLOW: Tobs of max(1040 periods,"$Tobs_min" sec) OR MSP:Tobs of max(1040 periods,1200 sec))" > "plot_"$Tobs_min"_"$array
echo "PSR             Tobs(s)         SNR" >> "plot_"$Tobs_min"_"$array
# Do the SNR and Tobs calculations and output to file
awk -v Nstations=$Nstations -v Tobs_min=$Tobs_min '{Tobs=$2*1040.0; if ($2>=0.030 && $2*1040 < Tobs_min) Tobs=Tobs_min; if ($2<0.030 && $2*1040 < 1200) Tobs=1200.0;SNR=Nstations*0.001*$4*sqrt(2.0*90.0*10^6*Tobs)/((1.0/$5)*(2.0*1380.0/512.0)*858.0); if (SNR<30) {Tobs=Tobs*(30.0/SNR)^2; SNR=30.0}; printf "%s\t%f\t%f\n",$1,Tobs,SNR}' PSRs_p0_dm_s150_fac1 | awk '{s+=$2; print $0,(s/(60*60))}' | cat -n >> "plot_"$Tobs_min"_"$array

death:
exit
