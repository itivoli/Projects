# Contents of Analysis.ps1
# Set-ExecutionPolicy RemoteSigned

# Compile (jic)
gcc .\GSHARESIM.c -o .\GSHARESIM

############ Begin Writing to file ############
echo "Report Data (MCF)`n" > outMCF.txt

############ Part A ############
echo "Part A: M = 4, N Varied" >> outMCF.txt

echo "N = 1" >> outMCF.txt
Write-Host "Running M = 4, N = 1, MCF"
./GSHARESIM 4 1 Inputs\mcf_trace.txt >> outMCF.txt

echo "N = 2" >> outMCF.txt
Write-Host "Running M = 4, N = 2, MCF"
./GSHARESIM 4 2 Inputs\mcf_trace.txt >> outMCF.txt

echo "N = 3" >> outMCF.txt
Write-Host "Running M = 4, N = 3, MCF"
./GSHARESIM 4 3 Inputs\mcf_trace.txt >> outMCF.txt

echo "N = 4" >> outMCF.txt
Write-Host "Running M = 4, N = 4, MCF"
./GSHARESIM 4 4 Inputs\mcf_trace.txt >> outMCF.txt

############ Part B ############
echo "Part B: M = Varied, N = 4" >> outMCF.txt

echo "M = 4" >> outMCF.txt
Write-Host "Running M = 4, N = 4, MCF"
./GSHARESIM 4 4 Inputs\mcf_trace.txt >> outMCF.txt

echo "M = 5" >> outMCF.txt
Write-Host "Running M = 5, N = 4, MCF"
./GSHARESIM 5 4 Inputs\mcf_trace.txt >> outMCF.txt

echo "M = 6" >> outMCF.txt
Write-Host "Running M = 6, N = 4, MCF"
./GSHARESIM 6 4 Inputs\mcf_trace.txt >> outMCF.txt

echo "M = 7" >> outMCF.txt
Write-Host "Running M = 7, N = 4, MCF"
./GSHARESIM 7 4 Inputs\mcf_trace.txt >> outMCF.txt

# Part C
echo "Part C: M = Varied, N = 0" >> outMCF.txt

echo "M = 4" >> outMCF.txt
Write-Host "Running M = 4, N = 0, MCF"
./GSHARESIM 4 0 Inputs\mcf_trace.txt >> outMCF.txt

echo "M = 5" >> outMCF.txt
Write-Host "Running M = 5, N = 0, MCF"
./GSHARESIM 5 0 Inputs\mcf_trace.txt >> outMCF.txt

echo "M = 6" >> outMCF.txt
Write-Host "Running M = 6, N = 0, MCF"
./GSHARESIM 6 0 Inputs\mcf_trace.txt >> outMCF.txt

echo "M = 7" >> outMCF.txt
Write-Host "Running M = 7, N = 0, MCF"
./GSHARESIM 7 0 Inputs\mcf_trace.txt >> outMCF.txt

echo "`n`n" >> outMCF.txt
Write-Host "All commands completed."

#Set-ExecutionPolicy Restricted