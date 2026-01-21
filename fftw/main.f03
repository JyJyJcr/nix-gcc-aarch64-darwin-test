PROGRAM main
  USE, intrinsic :: iso_c_binding
  INCLUDE "fftw3.f03"
  ! INTEGER, PARAMETER :: DP = selected_real_kind(14,200)
  INTEGER, PARAMETER :: DP = c_double_complex
  INTEGER :: nx,ny,nz
  TYPE(C_PTR) :: plan 
  COMPLEX(DP), ALLOCATABLE :: f_test(:)
  write(*,*) 'hello';flush(6)
  nx = 75
  ny = 120
  nz = 180
  ALLOCATE(f_test(nx*ny*nz))

  ! the issue is originally found when I wrote quantum-espresso package for darwin ...

  ! print-debug shows fftw plan constructing fails (NULL return) and finally causes SIGSEGV.

  ! I observed first two call of fftw_plan_many_dft in fft_scalar.FFTW3.f90/cfft3ds/init_plan (l684 and l678):
  ! https://github.com/QEF/q-e/blob/ddbec46536cc9c6f8cf3cd9db486573bcc5424a4/FFTXlib/src/fft_scalar.FFTW3.f90#L678-L684

  ! in my env, the first one (l684) succeeds but the second one (l678) fails
  ! then change gfortran from nix's to homebrew's resolved the problem



  ! the two blocks below replicate the same behaviour.
  ! for simplicity, I changed the external call as:
  !  ldx,ldy,ldz -> nx,ny,nz
  !  f_test(1:) -> f_test
  !  idir -> -1

  ! l684
  !plan = fftw_plan_many_dft(1, (/nz/), 1, &
  !          f_test, (/nz, ny, nx/), nx*ny, 1, &
  !          f_test, (/nz, ny, nx/), nx*ny, 1, &
  !          -1, FFTW_MEASURE)
  !if (C_ASSOCIATED(plan)) then
  !  write(*,*) 'secc';flush(6)
  !  call fftw_destroy_plan(plan)
  !else
  !  write(*,*) 'fail!';flush(6)
  !endif

  ! l678
  !plan = fftw_plan_many_dft(1, (/ny/), nz, &
  !          f_test, (/nz, ny, nx/), nx, nx*ny, &
  !          f_test, (/nz, ny, nx/), nx, nx*ny, &
  !          -1, FFTW_MEASURE)
  !if (C_ASSOCIATED(plan)) then
  !  write(*,*) 'secc';flush(6)
  !  call fftw_destroy_plan(plan)
  !else
  !  write(*,*) 'fail!';flush(6)
  !endif

  ! obviously this calling not follows fftw docs:
  ! https://www.fftw.org/fftw3_doc/Advanced-Complex-DFTs.html

  ! purifing, the actual minimal, and correct call is here.

  ! mem model:
  ! [ 1 o o 
  !   1 o o
  !   1 o o
  !   1 o o ]
  ! [ 2 o o
  !   2 o o
  !   2 o o
  !   2 o o ]
  ! nx = 3, ny = 4, nz = 2
  ! we run two set of dft, 1 and 2.
  ! between 1 and 2 = nx * ny so dist = nx * ny
  ! between 1 and 1 = nx so stride = nx
  ! num of dft = nz so howmany = nz
  ! the dft size = (ny) so n,embed = (ny)

  plan = fftw_plan_many_dft(1, (/ny/), nz, &
            f_test, (/ny/), nx, nx*ny, &
            f_test, (/ny/), nx, nx*ny, &
            -1, FFTW_MEASURE)
  if (C_ASSOCIATED(plan)) then
    write(*,*) 'succ';flush(6)
    call fftw_destroy_plan(plan)
  else
    write(*,*) 'fail!';flush(6)
  endif

  ! this fails with nix and succ with homebrew

  ! lldb shows ill stacking:
  ! x0 - x7 corresponds to 1, (/ny/), nz, f_test, (/ny/), nx, nx*ny, f_test
  ! then remained args are put in stack

  ! so break at the external call, then `memory read $sp -f d` and shows:

  ! nix

  ! (lldb) memory read $sp -f d
  ! 0x16fdf9580: 1876923936
  ! 0x16fdf9584: 1
  ! 0x16fdf9588: 75
  ! 0x16fdf958c: 0    <--- what
  ! 0x16fdf9590: 9000
  ! 0x16fdf9594: 0    <--- what
  ! 0x16fdf9598: -1
  ! 0x16fdf959c: 0    <--- maybe what
  
  ! homebrew

  ! (lldb) memory read $sp -f d
  ! 0x16fdf95c0: 1876924760
  ! 0x16fdf95c4: 1
  ! 0x16fdf95c8: 75
  ! 0x16fdf95cc: 9000
  ! 0x16fdf95d0: -1
  ! 0x16fdf95d4: 0
  ! 0x16fdf95d8: 0
  ! 0x16fdf95dc: 0

  ! nix one contains additional paddings.
  ! so this must abi failure.

  ! compile:
  ! (nix)      gfortran main.f90 -o main $(pkg-config --libs --cflags fftw3)
  ! (homebrew) /opt/homebrew/bin/gfortran main.f90 -o main $(pkg-config --libs --cflags fftw3)

  DEALLOCATE(f_test)
END PROGRAM main
