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

############# SOURCES #######################
filename="a02"

############# GLOBAL VARIABLES ################
window_size = 10 #seconds
sr=1000 #Sample rate
ns = window_size * rate_sample #number of samples

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
threshold = 30 # mV
#(AECG_clean) = MedianFilter(AECG_fnotch,threshold,window)
AECG_clean = AECG_fnotch

########## SOURCE SEPARATION ################
#----------------- ICA ----------------------
nc = nch # number of components
(AECG_white) = MakeICAll(AECG_clean,nch,ns)

#------------ Sort ICA results ----------------------
#(AECG_sort)=SortICA(AECG_white)
#----------- Resamplig signal -----------------------
#fact=2 # factor to resample the signal
#(t_resmp,AECG_resample) = InterpSignal(AECG_white)
#----------- QRS mother detector -----------------------
(QRSm_pos,QRSm_value)= QRSm_detector(AECG_white,ns,sr)
heart_rate_mother = (60*size(QRSm_pos,1))/window_size
#------- SVD process and subtract mother signal---------
(SVDrec,AECGm) = Font_Separation_SVD(AECG_clean, QRSm_pos,sr,nch,ns);
AECGf = MakeICAfeto(AECGm,nc,nch)
#AECGf2 = QRSf_selector(AECGf)
@time (QRSf_pos,QRSf_value)= QRSf_detector(AECGf,ns,sr)
heart_rate_feto = (60*size(QRSf_pos,1))/window_size

