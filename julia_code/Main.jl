############## LIBRARIES ##############
using MultivariateStats, Base.Test, DataFrames, PyPlot, DSP

############# FUNCTIONS ####################
include("process_svs.jl")
include("process_txt.jl")
include("Notch_Filter_Detrent.jl")
include("MakeICAll.jl")
include("SortICA.jl")
include("InterpSignal.jl")
include("QRSm_detector.jl")
include("QRSf_detector.jl")
include("QRSf_selector.jl")
include("MedianFilter.jl")
include("Font_Separation_SVD.jl")
include("MakeICAfeto.jl")
include("Plotting.jl")
include("pan_tomkins_detector.jl")

############# SOURCES #######################
filename="a01"

############# GLOBAL VARIABLES ################
window_size = 30 #seconds
sr=1000 #Sample rate
ns = window_size * sr #number of samples

############ LOAD DATA ######################
#----------- Read and fix data --------------
(t,AECG) = process_svs(filename)
fetal_annot = process_txt(filename,ns)

#----------- Load data according global varaibles ----
AECG = AECG[1:ns,:]
t = t[1:ns,:]
nch = size(AECG,2) # nch - number of channels

# ########### PREPROCESING ####################
#------- Notch Filtering and detrending ------------
(AECG_fnotch, lowSignal) = notch_filter(AECG, sr)
#----------- Median filter ----------------
window = 2000 # size of window in number of samples
#(AECG_clean) = MedianFilter(AECG_fnotch,window,ns,nch,sr)
AECG_clean = AECG_fnotch
#println(maximum(AECG_clean));

########## SOURCE SEPARATION ################
#----------------- ICA ----------------------
nc = nch # number of components
(AECG_white) = MakeICAll(AECG_clean,nch,nc)

println(maximum(AECG_clean));


#------------ Sort ICA results ----------------------
#(AECG_sort)=SortICA(AECG_white)
#----------- Resamplig signal -----------------------
#fact=2 # factor to resample the signal
#(t_resmp,AECG_resample) = InterpSignal(AECG_white)


#------------ Pan - Tomkins Detector QRS------------------

(QRSm_pos, QRSm_value)=Pan_Tomkins_Detector(AECG_white, sr);

#---------------------------------------------------------
#----------- QRS mother detector -----------------------
#(QRSm_pos,QRSm_value)= QRSm_detector(AECG_white,ns,sr)
heart_rate_mother = (60*size(QRSm_pos,1))/window_size

#------- SVD process and subtract mother signal---------

(SVDrec,AECGm) = Font_Separation_SVD(AECG_clean,QRSm_pos,sr,nch,ns);
AECGf = MakeICAfeto(AECGm,nc,nch)
AECGf2 = QRSf_selector(AECGf, nc)
#@time (QRSf_pos,QRSf_value)= QRSf_detector(AECGf,ns,sr)

(QRSf_pos,QRSf_value)= Pan_Tomkins_Detector(AECGf, sr)

heart_rate_feto = (60*size(QRSf_pos,1))/window_size


## Detector ECG feto con filtro derivativo
#nu=convert(Int64, ceil(0.005*sr));
#nz=convert(Int64, floor(0.003*sr/2)*2+1);
#B=vcat(ones(nu,1), zeros(nz,1), -1*ones(nu,1))
#delay=convert(Int64, floor(length(B)/2));

#ecgfx=vcat(repmat(AECGf2[1,:],1,delay)', AECGf, repmat(AECGf2[end,:],1,delay)')
#der=PolynomialRatio(vec(B),[1])

#ecg_der=filt(der,ecgfx);

#ecg_der=ecg_der[2*delay+1:end,:]


#responseType=Bandpass(0.7,8;fs=sr)
#designMethod=Butterworth(10);
#salida = filtfilt(digitalfilter(responseType, designMethod), ecg_der);

