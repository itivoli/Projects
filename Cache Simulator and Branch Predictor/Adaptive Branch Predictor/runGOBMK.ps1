# Contents of Analysis.ps1
# Set-ExecutionPolicy RemoteSigned

# Compile (jic)
gcc .\GSHARESIM.c -o .\GSHARESIM

############ Begin Writing to file ############
echo "Report Data (GOBMK)`n" > outGOBMK.txt

############ Part A ############
echo "Part A: M = 4, N Varied" >> outGOBMK.txt

echo "N = 1" >> outGOBMK.txt
Write-Host "Running M = 4, N = 1, GoBMK"
./GSHARESIM 4 1 Inputs\gobmk_trace.txt >> outGOBMK.txt

echo "N = 2" >> outGOBMK.txt
Write-Host "Running M = 4, N = 2, GoBMK"
./GSHARESIM 4 2 Inputs\gobmk_trace.txt >> outGOBMK.txt

echo "N = 3" >> outGOBMK.txt
Write-Host "Running M = 4, N = 3, GoBMK"
./GSHARESIM 4 3 Inputs\gobmk_trace.txt >> outGOBMK.txt

echo "N = 4" >> outGOBMK.txt
Write-Host "Running M = 4, N = 4, GoBMK"
./GSHARESIM 4 4 Inputs\gobmk_trace.txt >> outGOBMK.txt

############ Part B ############
echo "Part B: M = Varied, N = 4" >> outGOBMK.txt

echo "M = 4" >> outGOBMK.txt
Write-Host "Running M = 4, N = 4, GoBMK"
./GSHARESIM 4 4 Inputs\gobmk_trace.txt >> outGOBMK.txt

echo "M = 5" >> outGOBMK.txt
Write-Host "Running M = 5, N = 4, GoBMK"
./GSHARESIM 5 4 Inputs\gobmk_trace.txt >> outGOBMK.txt

echo "M = 6" >> outGOBMK.txt
Write-Host "Running M = 6, N = 4, GoBMK"
./GSHARESIM 6 4 Inputs\gobmk_trace.txt >> outGOBMK.txt

echo "M = 7" >> outGOBMK.txt
Write-Host "Running M = 7, N = 4, GoBMK"
./GSHARESIM 7 4 Inputs\gobmk_trace.txt >> outGOBMK.txt

# Part C
echo "Part C: M = Varied, N = 0" >> outGOBMK.txt

echo "M = 4" >> outGOBMK.txt
Write-Host "Running M = 4, N = 0, GoBMK"
./GSHARESIM 4 0 Inputs\gobmk_trace.txt >> outGOBMK.txt

echo "M = 5" >> outGOBMK.txt
Write-Host "Running M = 5, N = 0, GoBMK"
./GSHARESIM 5 0 Inputs\gobmk_trace.txt >> outGOBMK.txt

echo "M = 6" >> outGOBMK.txt
Write-Host "Running M = 6, N = 0, GoBMK"
./GSHARESIM 6 0 Inputs\gobmk_trace.txt >> outGOBMK.txt

echo "M = 7" >> outGOBMK.txt
Write-Host "Running M = 7, N = 0, GoBMK"
./GSHARESIM 7 0 Inputs\gobmk_trace.txt >> outGOBMK.txt

echo "`n" >> outGOBMK.txt
Write-Host "All commands completed."

#Set-ExecutionPolicy Restricted