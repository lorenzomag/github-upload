C.
      SUBROUTINE gudigi
C.
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C                                                                      C
C     SUBROUTINE GUDIGI is called at the end of each event             C
C                                                                      C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C.
      IMPLICIT none
C.
      include 'gcflag.inc'          !geant
      include 'cntrs.inc'           !local
C.
      INTEGER itrig
C.
      itrig = 0
C.
      CALL anadet(itrig)
C.
      If(itrig.eq.0)then
CCC        ieotri = 1
      Else
        CALL dhpmt
      Endif
C.
      CALL interac


      RETURN
      END
C.
      SUBROUTINE anadet(itrig)
C.
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C                                                                      C
C     SUBROUTINE ANADET reads the scintillator hits and determines     C
C     whether or not an event has fulfilled the trigger condition      C
C                                                                      C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C.
      IMPLICIT none
C.
      include 'gcbank.inc'          !geant
      include 'gcflag.inc'          !geant
      include 'gcunit.inc'          !geant
C.
      include 'uenergy.inc'		!local
      include 'geometry.inc'		!local
      include 'ev_info.inc'		!local
      include 'runstats.inc'            !local
      include 'gbox_info.inc'           !local
      include 'rescom.inc'              !local
      include 'cntrs.inc'               !local
      include 'gammahit.inc'
C.      include 'gctrak.inc'
C.
      INTEGER i, j, k, n, itrig
      INTEGER hit, hit_param
      INTEGER nset, iset, js, ndet, idet, jd, nv, nh
C.
      INTEGER nvdim, nhdim, nhmax 
C.
      PARAMETER (nvdim = 1)
C.
      PARAMETER (nhdim =  5)
      PARAMETER (nhmax = 500)
C.
      INTEGER numvs(nvdim),numbv(nvdim,nhmax),numbv_temp(nvdim,nhmax)
      DATA numvs / nvdim*0 /
C.
      INTEGER nhits, nhits_temp, itra(nhmax)
      REAL hits(nhdim,nhmax),hits_temp(nhdim,nhmax)
C.
      CHARACTER*4 iudet
C.
      INTEGER mhit
      PARAMETER ( mhit = 500 )

      REAL rndm(2)
C.
C *** nelem:    	Number of all 'struck' scintillators
C *** melem:            Number of 'struck' modules of detector
C *** jelem:            Volume # of 'struck' modules
C.
      INTEGER nelem, melem
      INTEGER jelem(nvdim,mhit), itr(mhit)
      INTEGER isort(mhit)
C.
      REAL coord(3,mhit), time(mhit), energy(mhit),fcoord(3,mhit)
C.
      REAL E_energy
      REAL rndvec(1), resn, thresh
C.
      INTEGER iclu
C.
      INTEGER index(mclu)
      REAL cthres / 0.0 /
C.
      REAL etmp(mclu)
C JS adds e_bgos_deposit to record energy deposited in each BGO,
C   one position in array per BGO
      REAL e_bgos_deposit(30,2)
C.
      If(jhits.le.0)RETURN                    !
C.                                            !
      nset = iq(jset-1)                       ! This tests ZEBRA pointer
      CALL glook('SCNB',iq(jset+1),nset,iset) ! that hits are initialized.  
      If(iset.le.0)goto 999                   !
C.                                            ! iset is set no. of DIGI
      js = lq(jset-iset)                      !
      if(js.le.0)goto 999                     !
      ndet = iq(js-1)                         ! ndet=no. of detectors in iset
C.
      CALL vzero(jelem,nvdim*mhit)
      CALL vzero(itr,mhit)
      CALL vzero(coord,3*mhit)
      CALL vzero(fcoord,3*mhit)
      CALL vzero(time,mhit)
      CALL vzero(energy,mhit)
C.
      melem = 0
C.
      E_energy = 0.0
C.
C     Threshold: testing of threshold effect (initialised in uvinit.f or 
C     dragon_2003.ffcards).
      CALL rnorml(rndvec,1)
      thresh = E_threshold*(1. + rndvec(1)*0.05)
C.
      print*, "ndet is ", ndet
C.
C. LP: temporary changes to be confirmed    
      nhits_temp = 0
      CALL vzero(hits_temp,nhdim*nhmax)
      CALL vzero(hits,nhdim*nhmax)
      CALL vzero(numbv,nhmax)
      CALL vzero(numbv_temp,nhmax)
C.
      Do 100 idet = 1, ndet
C.
         CALL uhtoc(iq(js+idet),4,iudet,4)
         CALL gsatt(iudet,'SEEN',-1)
C.
         jd = lq(js-idet)            ! More Zerbra Integrity tests
C.
         nv = iq(jd+2)                   
         nh = iq(jd+4)
         If(nv.ne.nvdim)goto 999
         If(nh.ne.nhdim)goto 999     !
C.
C     For debugging Purposes
C         print*, "BEFORE. idet ", idet
C         print*, "iudet, nv, nh, nhmax", iudet, nv, nh, nhmax
C         print*, "numbv", numbv
C         print*, "hits", hits
C         print*, "nhits", nhits
C
         CALL gfhits('SCNB',iudet,nv,nh,nhmax,0,
     &               numvs,itra,numbv,hits,nhits)
C     For debugging Purposes
C         print*, "AFTER. idet ", idet
C         print*, "iudet, nv, nh, nhmax", iudet, nv, nh, nhmax         
C         print*, "numbv", numbv
C         print*, "hits", hits
C         print*, "nhits", nhits
         
C 
         If(nhits.eq.0)goto 100
         CALL gsatt(iudet,'SEEN',0)
C.
         If(nhits.gt.nhmax)then
           Write(lout,*)' Problem in ANADET for event: ',ievent
           Write(lout,*)' Number of hits ',nhits,' > nhmax ',nhmax
           nhits = min(nhmax,nhits)
         Endif
C.
         Do hit = nhits_temp+1, nhits+nhits_temp
            Do hit_param = 1, nhdim
               hits_temp(hit_param,hit)=hits(hit_param,hit-nhits_temp)
            Enddo
            Do hit_param = 1, nvdim
               numbv_temp(hit_param,hit)=numbv(hit_param,hit-nhits_temp)
            Enddo
         Enddo
         nhits_temp = nhits_temp + nhits
C.
         Do 10 j = 1, nhits
C          
            Do k = 1, melem
               If(numbv(1,j).eq.jelem(1,k))then
                    coord(1,k)=coord(1,k)+hits(5,j)*hits(1,j) !summing hits of
                    coord(2,k)=coord(2,k)+hits(5,j)*hits(2,j) !same module.
                    coord(3,k)=coord(3,k)+hits(5,j)*hits(3,j)
                    fcoord(1,k)=hits(1,j) !AO real finger coords
                    fcoord(2,k)=hits(2,j) 
                    fcoord(3,k)=hits(3,j)
                    
                    time(k) = min(time(k),hits(4,j))
                    energy(k) = energy(k) + hits(5,j)
                    call rnorml(rndvec,1)
C     gaussian distributed resolution dependent on energy: 
C     Resolution based on linear fit to values of 14% for 661 keV and 
C     4% for 10 MeV.(Temporary until I find the real resolution function).
                    resn = 0.14 - 0.001*energy(k)
                    energy(k) = energy(k)*(1.0 + rndvec(1)*resn)

                    goto 10
               Endif
            Enddo
C     
            If(melem.ge.mhit)goto 998
            melem = melem + 1
C.
            CALL ucopy(numbv(1,j),jelem(1,melem),1)
            
C.
            itr(melem) = itra(j)
            coord(1,melem) = hits(5,j)*hits(1,j)
            coord(2,melem) = hits(5,j)*hits(2,j)
            coord(3,melem) = hits(5,j)*hits(3,j)
            fcoord(1,melem)=hits(1,j) !AO real finger coords
            fcoord(2,melem)=hits(2,j) 
            fcoord(3,melem)=hits(3,j)
            time(melem) = hits(4,j)
            energy(melem) = hits(5,j)
C.
   10    Continue
C.
  100 Continue
      nhits = nhits_temp
      Do i = 1, nhmax
         Do j = 1, nhdim
            hits(j,i) = hits_temp(j,i)
         Enddo
         Do j = 1, nvdim
            numbv(j,i) = numbv_temp(j,i)
         Enddo
      Enddo
      print*, numbv
C
C.--> Sorts 'energy' vector in terms of decreasing energy (so that 
C.--> 'energy(isort(1))' is highest E.
      If(melem.eq.0)RETURN
C.
      CALL sortzv(energy,isort,melem,1,1,0)
C.
      Do k = 1, melem
C.
         e_detect   = e_detect   + energy(k)
C.
         coord(1,k) = coord(1,k)/energy(k)
         coord(2,k) = coord(2,k)/energy(k)
         coord(3,k) = coord(3,k)/energy(k)
C.
         CALL hfill( 33,fcoord(1,k),0.0,1.0)
         CALL hfill( 34,fcoord(2,k),0.0,1.0)
         CALL hfill( 35,fcoord(3,k),0.0,1.0)
         CALL hfill( 25,time(melem), z_react ,1.0)
C.
         CALL hfill( 36,energy(k),0.0,1.0)
         If(k.le.4)then
           CALL hfill( 36+k,energy(isort(k)),0.0,1.0)
         Endif
C.
      Enddo
C.
      x_max = coord(1,isort(1))    !energy weighted coords of the 
      y_max = coord(2,isort(1))    !highest energy module
      z_max = coord(3,isort(1))
C. 
C.--> Extract time variable of highest E gamma hit
      gammatof = time(isort(1))
C.      print*, 'TOF Gamma = ', gammatof
C.---> Add some timing 'resolution' (say sigma=200ps)[time in ns]
      CALL granor(rndm(1),rndm(2))
C.
      gammatofp = gammatof
      gammatof = gammatof + rndm(1)*0.3
C.
      ifngr_max = jelem(1,isort(1))
      neff(11,ifngr_max) = neff(11,ifngr_max) + 1
C.
      melem_gbox = melem           !melem = no. of modules hit
      Do k = 1, melem
         E_energy = E_energy + energy(k)
         jelem_gbox(1,k) = jelem(1,isort(k))
         energy_gbox(k) = energy(isort(k))
      Enddo
C.      
      If(iswit(4).eq.1)then
        write(lunits(3),*)melem_gbox
        Do k = 1, melem_gbox                                !store ordered by
           write(lunits(3),*)jelem_gbox(1,k),energy_gbox(k) !energy  
        Enddo
      Elseif(iswit(4).eq.2)then
        Call hfnt(999)
      Endif
C.
      nelem = 0
C.
      If(E_energy.gt.0.0)nelem = nelem + 1

      CALL hfill( 41,E_energy,0.0,1.0)

C.
      If(nelem.gt.0)itrig = itrig + 1
C.
      If(nelem.eq.0)RETURN
C.
      CALL hfill( 31,1.*melem+0.5,0.0,1.0)
      CALL rnorml(rndvec,1)
      
C     Total energy.
      CALL hfill( 32,e_detect,0.0,1.0)
     
C.      
      Do i = 1, Nn
         E_energy = 0.0
         Do 11 j = 1, i
            If(n_fngr(j,ifngr_max).ne.0)then
              Do k = 1, melem
                 If(n_fngr(j,ifngr_max).eq.jelem(1,isort(k)))then
                   E_energy = E_energy + energy(isort(k))
                   Goto 11
                 Endif
              Enddo
            Else
              Goto 1
            Endif
   11    Continue
    1    CALL hfill(130+i,1.*ifngr_max+0.5,E_energy,1.0)
         If(E_energy.gt.thresh)then
           neff(i,ifngr_max) = neff(i,ifngr_max) + 1
         Endif
      Enddo
C.      
      CALL genclu(melem,jelem,nclu,nhit,jhit)   ! generate clusters of modules
C.     
      CALL vzero(eclu,mclu)
      CALL vzero(etmp,mclu)
      CALL vzero(xclu,mclu)
      CALL vzero(yclu,mclu)
      CALL vzero(zclu,mclu)
C.
      Do iclu = 1, nclu
         Do j = 1, nhit(iclu)
            Do k = 1, melem
               If(jelem(1,k) .eq. jhit(j,iclu))then
                 etmp(iclu) = etmp(iclu) + energy(k)
                 xclu(iclu) = xclu(iclu) + 
     &                                  x_fngr(jhit(j,iclu)) * energy(k)
                 yclu(iclu) = yclu(iclu) +
     &                                  y_fngr(jhit(j,iclu)) * energy(k)
                 zclu(iclu) = zclu(iclu) +
     &                                  z_fngr(jhit(j,iclu)) * energy(k)
                !x_fngr,etc, are positions of crystals in mother space
       
               Endif
            Enddo 
         Enddo
      Enddo
      n = nclu
      nclu = 0
      Do iclu = 1, n
         If(etmp(iclu).gt.cthres)then
           nclu = nclu + 1
           etmp(nclu) = etmp(iclu)
           xclu(nclu) = xclu(iclu)/etmp(iclu)
           yclu(nclu) = yclu(iclu)/etmp(iclu)
           zclu(nclu) = zclu(iclu)/etmp(iclu)
           nhit(nclu) = nhit(iclu)
           CALL ucopy2(jhit(1,iclu),jhit(1,nclu),nhit(iclu))
         Endif
      Enddo
C.
      
      CALL sortzv(etmp,index,nclu,1,-1,0)
C.
      CALL hfill( 90,1.*nclu+0.5,0.0,1.0)
      Do iclu = 1, nclu
         eclu(iclu) = etmp(index(iclu))
         dir_clu(1,iclu) = xclu(index(iclu))
         dir_clu(2,iclu) = yclu(index(iclu))
         dir_clu(3,iclu) = zclu(index(iclu))
         CALL vunit(dir_clu(1,iclu),dir_clu(1,iclu),3) !direction vector of the
         If(iclu.le.3)then                             !cluster
           CALL hfill( 90+iclu,eclu(iclu),0.0,1.0)
         Endif
      Enddo
C
C     JS code to count # of BGOs triggered
C     and energy deposited in triggered BGOs.
C
C     reset variables from previous event
      Do i = 1, 30
         e_bgos_deposit(i,1) = 0
         e_bgos_deposit(i,2) = 0
      Enddo
C     loop over all hits, find out which BGO recorded the hit, numbv(1,i), and
C     then store the energy from that hit, hits(5,i), in the array, at the
C     index position of the hit BGO      
      Do i = 1, nhits
         e_bgos_deposit(numbv(1,i),1) = numbv(1,i)
         e_bgos_deposit(numbv(1,i),2) = e_bgos_deposit(numbv(1,i),2)+ 
     &                                                         hits(5,i)
      Enddo      
C     Sort the array with insertion sort, bringing most energetic BGO to
C     first position, second most energetic BGO to second position, etc.
C     Any BGO hits less than threshold (0.1 MeV) are removed.
      if (e_bgos_deposit(1,2).lt.0.1)then
         e_bgos_deposit(1,1) = 0
         e_bgos_deposit(1,2) = 0
      endif
      Do i = 2, 30
         if (e_bgos_deposit(i,2).lt.0.1)then
            e_bgos_deposit(i,1) = 0
            e_bgos_deposit(i,2) = 0
            continue
         endif
         do j = i, 2, -1
            if (e_bgos_deposit(j,2).gt.e_bgos_deposit(j-1,2))then
               num_bgo_first_ab = e_bgos_deposit(j-1,1)
               e_bgo_first_ab = e_bgos_deposit(j-1,2)
               e_bgos_deposit(j-1,1) = e_bgos_deposit(j,1)
               e_bgos_deposit(j-1,2) = e_bgos_deposit(j,2)
               e_bgos_deposit(j,1) = num_bgo_first_ab
               e_bgos_deposit(j,2) = e_bgo_first_ab
            endif
         enddo
         num_bgo_first_ab = 0
         e_bgo_first_ab = 0
      enddo
C     Scroll through array, count BGOs, sum energys
      Do i = 1, 30
         if (e_bgos_deposit(i,1).ne.0) then
            num_bgos_hit = num_bgos_hit + 1
            e_bgos_total = e_bgos_total + e_bgos_deposit(i,2)
         else
            exit
         endif
      enddo
      num_bgo_first = e_bgos_deposit(1,1)      
      e_bgo_first = e_bgos_deposit(1,2)
C     Determining material of detection
      isBGO=0
      isLaBr3=0
      If(det_mate(num_bgo_first).eq.0)then
         isBGO=1
         print*, "HIT: BGO detector number", num_bgo_first,
     + " detected most energetic photon."
      Endif
      If(det_mate(num_bgo_first).eq.1)then
         isLaBr3=1
         print*, "HIT: LaBr3 detector number", num_bgo_first,
     + " detected most energetic photon."
      Endif
C
      If(isBGO.eq.1.and.isLaBr3.eq.1)then
        print*, "ERROR with material variables"
        go to 997
      Endif
C	Add resolution function of form sigma = FWHM/2.35 = h*sqrt(E)/2.35
C
      call granor(rndm(1),rndm(2))
C.
      If(isBGO.eq.1)then
C        e0_conv = e_bgo_first + rndm(1)*0.1733*sqrt(e_bgo_first)/2.35
         e0_conv = e_bgo_first + rndm(1)*0.0789*sqrt(e_bgo_first)/2.35  !LP: h based on FWHM of 9.7%
      Else if(isLaBr3.eq.1)then
         e0_conv = e_bgo_first + rndm(1)*0.0179*sqrt(e_bgo_first)/2.35   !LP: h based on FWHM of 2.2%
      Endif
C
      num_bgo_second = e_bgos_deposit(2,1)
      e_bgo_second = e_bgos_deposit(2,2)
C     Use adjacency matrix to addback BGOs, if more than one BGO hit
C     Count BGOs and energys as well
      num_bgos_hit_ab = num_bgos_hit
      if (num_bgos_hit.ne.1)then
      Do i = 1, num_bgos_hit - 1
         do j = i + 1, num_bgos_hit
           if(e_bgos_deposit(i,1).ne.0.and.e_bgos_deposit(j,1).ne.0)then
            if(adjacency_matrix(e_bgos_deposit(i,1),e_bgos_deposit(j,1))
     &                                                       .eq.1) then
             e_bgos_deposit(i,2)=e_bgos_deposit(i,2)+e_bgos_deposit(j,2)
             e_bgos_deposit(j,1) = 0
             e_bgos_deposit(j,2) = 0
             num_bgos_hit_ab = num_bgos_hit_ab - 1
            endif
           endif
         enddo
      enddo
      endif
      Do i = 1, num_bgos_hit
         if (e_bgos_deposit(i,1).ne.0) then
            if (num_bgo_first_ab.eq.0) then
               num_bgo_first_ab = e_bgos_deposit(i,1)
               e_bgo_first_ab = e_bgos_deposit(i,2)
            elseif (num_bgo_second_ab.eq.0) then
               num_bgo_second_ab = e_bgos_deposit(i,1)
               e_bgo_second_ab = e_bgos_deposit(i,2)
               exit
            endif
         endif
      enddo
C     Filling the appropriate histograms
      if (recoil_hit_ENDV.eq.1) then
         CALL hfill(511, 1.0*num_bgos_hit, 0.0, 1.0)
         CALL hfill(512, 1.0*e_bgos_total, 0.0, 1.0)
         CALL hfill(513, 1.0*num_bgos_hit, e_bgos_total, 1.0)
         CALL hfill(514, e_bgo_first, e_bgo_second, 1.0)
         CALL hfill(515, num_bgo_first, num_bgo_second, 1.0)
      endif
C     For debugging purposes
C      print*, nhits
C      print*, numbv
C      print*, e_bgos_deposit
C       print*, e_bgos_deposit_total
C       print*, num_bgos_hit
C.
C *** nelem:  Total Number of Scintillator hits
C     
      print*, "nelem", nelem
      print*, "melem", melem
      print*, "jelem", jelem
C *** jelem:  Array of Module indices (k=1,melem)
C.
C.                         jelem(1,k) -> Module    Number
C.
C *** itr(k): Track number causing the kth GEANT hit
C.
C *** coord:  Coordinates Array of Scintillator [cm]
C.
C             coord(1,k): Energy weighted x-coordinate
C             coord(2,k): Energy weighted y-coordinate
C             coord(3,k): Energy weighted z-coordinate
C.
C *** time:   min(tof) - abs. GEANT time of flight [ns] (from event time0)
C.
C *** energy: Total energy [MeV] deposited in module
C.
C *** E_energy: Total energy [MeV] deposited in scintillator
C.
      RETURN
C.
  997 Continue       !LP
C.
      Write(lout,*)' *** Problem in ANADET *** for event: ',ievent
      Write(lout,*)'Highest energy photon for both BGO and LaBr3 
     + considered simultaneously'
C.
      RETURN
C.
  998 Continue
C.
      Write(lout,*)' *** Problem in ANADET *** for event: ',ievent
      Write(lout,*)' Number of elements melem ',melem,' > maximum '
C.
      RETURN
C.
  999 Continue
C.
      Write(lout,*)' *** Problem in ANADET --- STOP!!! *** '
      Write(lout,*)' GEANT HIT Bank not properly set up! '
C.
      STOP
      END
C.
C.
      SUBROUTINE dhpmt
C.
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C                                                                      C
C     SUBROUTINE DHPMT reads the PMT hits, digitizes and records ADC   C
C     and TDC hits in the PMTs                                         C
C                                                                      C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C.
      IMPLICIT none
C.
      include 'gcbank.inc'          !geant
      include 'gcflag.inc'          !geant
      include 'gcunit.inc'          !geant
C.
      include 'ev_info.inc'		!local
      include 'uenergy.inc'             !local
C.
      INTEGER i, j, k
C.
      INTEGER nset, iset, js, ndet, idet, jd, nv, nh
C.
      INTEGER nvdim, nhdim, nhmax 
C.
      PARAMETER (nvdim = 1)
C.
      PARAMETER (nhdim =  5)
      PARAMETER (nhmax = 10000)
C.
      INTEGER numvs(nvdim),numbv(nvdim,nhmax)
      DATA numvs / nvdim*0 /
C.
      INTEGER nhits, itra(nhmax)
      REAL hits(nhdim,nhmax)
C.
      CHARACTER*4 iudet
C.
      INTEGER mhit
      PARAMETER ( mhit = 20 )
C.
C *** nelem:    	Number of all 'struck' PMTs
C *** jelem:            Volume # of 'struck' PMT
C.
      INTEGER nelem
      INTEGER jelem(nvdim,mhit), itr(mhit)
      INTEGER isort(mhit)
C.
      REAL coord(3,mhit), time(mhit), energy(mhit)
C.
      If(jhits.le.0)RETURN
C.
      nset = iq(jset-1)
      CALL glook('PMT ',iq(jset+1),nset,iset)
      If(iset.le.0)goto 999
C.
      js = lq(jset-iset)
      if(js.le.0)goto 999
      ndet = iq(js-1)
C.
      CALL vzero(jelem,nvdim*mhit)
      CALL vzero(coord,3*mhit)
      CALL vzero(time,mhit)
      CALL vzero(energy,mhit)
C.
      nelem = 0
      edetect = 0.0
C.
      Do 100 idet = 1, ndet
C.
         CALL uhtoc(iq(js+idet),4,iudet,4)
C.
         jd = lq(js-idet)
C.
         nv = iq(jd+2)
         nh = iq(jd+4)
         If(nv.ne.nvdim)goto 999
         If(nh.ne.nhdim)goto 999
C.
         CALL gfhits('PMT ',iudet,nv,nh,nhmax,0,
     &               numvs,itra,numbv,hits,nhits)
C.
         If(nhits.eq.0)goto 100
C.
         If(nhits.gt.nhmax)then
           Write(lout,*)' Problem in DHPMT for event: ',ievent
           Write(lout,*)' Number of hits ',nhits,' > nhmax ',nhmax
           nhits = min(nhmax,nhits)
         Endif
C.
         Do 10 j = 1, nhits
C.
            Do k = 1, nelem
               If(numbv(1,j).eq.jelem(1,k))then
                 coord(1,k)=coord(1,k)+hits(5,j)*hits(1,j)
                 coord(2,k)=coord(2,k)+hits(5,j)*hits(2,j)
                 coord(3,k)=coord(3,k)+hits(5,j)*hits(3,j)
                 time(k) = min(time(k),hits(4,j))
                 energy(k) = energy(k) + hits(5,j)
                 goto 10
               Endif
            Enddo
C.
            If(nelem.ge.mhit)goto 998
            nelem = nelem + 1
C.
            CALL ucopy(numbv(1,j),jelem(1,nelem),1)
            coord(1,nelem) = hits(5,j)*hits(1,j)
            coord(2,nelem) = hits(5,j)*hits(2,j)
            coord(3,nelem) = hits(5,j)*hits(3,j)
            time(nelem) = hits(4,j)
            energy(nelem) = hits(5,j)
C.
   10    Continue
C.
  100 Continue
C.
      ntot = nelem
      If(nelem.eq.0)RETURN
C.
      x_mean = 0.0
      y_mean = 0.0
C.
      CALL sortzv(energy,isort,nelem,1,1,0)
C.
      ntot = 0
C.
      Do k = 1, nelem
C.
         If(energy(k).gt.pmt_thrshld)ntot = ntot + 1
C.
         edetect   = edetect + max((energy(k)-pmt_thrshld),0.)
C.
         x_mean = x_mean + 
     &            (coord(1,k)/energy(k))*max((energy(k)-pmt_thrshld),0.)
         y_mean = y_mean +
     &            (coord(2,k)/energy(k))*max((energy(k)-pmt_thrshld),0.)
         z_mean = z_mean +
     &            (coord(3,k)/energy(k))*max((energy(k)-pmt_thrshld),0.)
C.
         CALL hfill( 51,energy(k),0.0,1.0)
         If(k.le.4)then
           CALL hfill( 51+k,energy(isort(k)),0.0,1.0)
         Endif
C.
      Enddo
C.
      CALL hfill( 56,1.*ntot+0.5,0.0,1.0)
      CALL hfill( 57,edetect,0.0,1.0)
C.
      If(nloss(1).gt.0)CALL hfill( 72,1.*nloss(1)+0.5,0.0,1.0)
      If(nloss(2).gt.0)CALL hfill( 73,1.*nloss(2)+0.5,0.0,1.0)
      If(nloss(3).gt.0)CALL hfill( 74,1.*nloss(3)+0.5,0.0,1.0)
      If(nloss(4).gt.0)CALL hfill( 75,1.*nloss(4)+0.5,0.0,1.0)
      If(nloss(5).gt.0)CALL hfill( 76,1.*nloss(5)+0.5,0.0,1.0)
      If(nloss(6).gt.0)CALL hfill( 77,1.*nloss(6)+0.5,0.0,1.0)
C.
      If(ntot.eq.0)RETURN
C.
      x_mean = x_mean/edetect
      y_mean = y_mean/edetect
      z_mean = z_mean/edetect
C.
C *** nelem:  Total Number of PMT  hits
C.
C *** jelem:  Array of PMT indices (k=1,nelem)
C.
C.                         jelem(1,k) -> PMT Number
C.
C *** coord:  Coordinates Array of PMT hits [cm]
C.
C             coord(1,k): Energy weighted x-coordinate
C             coord(2,k): Energy weighted y-coordinate
C             coord(3,k): Energy weighted z-coordinate
C.
C *** time:   min(tof) - abs. GEANT time of flight [ns] (from event time0)
C.
      RETURN
C.
  998 Continue
C.
      Write(lout,*)' *** Problem in DHPMT *** for event: ',ievent
      Write(lout,*)' Number of elements nelem ',nelem,' > maximum '
C.
      RETURN
C.
  999 Continue
C.
      Write(lout,*)' *** Problem in DHPMT --- STOP!!! *** '
      Write(lout,*)' GEANT HIT Bank not properly set up! '
C.
      STOP
      END
C.
C.
C.
      SUBROUTINE genclu(nelem,jelem,nclu,nhit,jhit)
C.
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C                                                                      C
C     Routine returns the total number of clusters found; the          C
C     number of elements in these clusters; and the index list         C
C     of these elements.                                               C
C                                                                      C
C     Input:  nelem            - number of 'struck' modules            C
C             jelem(ielem)     - volume # of 'struck' module           C
C                                                                      C
C     Output: nclu             - # of clusters found                   C
C             nhit(iclu)       - # number of elements in cluster       C
C             jhit(ihit,iclu)  - volume #'s of these elements          C
C                                                                      C
C     Author:   Peter Gumplinger                                       C
C     Date:     15. April 1994                                         C
C     Modified: 14. June 1994                                          C
C                                                                      C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C.
      IMPLICIT none
C.
      include 'gcflag.inc'          !geant
      include 'gcunit.inc'          !geant
C.
      include 'geometry.inc'            !local
C.
C.    mclu:             Max. number of clusters allowed
C.    mhit:             Max. number of elements in cluster
C.    mstack:           Max. number of entries on the stack
C.
      INTEGER mclu
      PARAMETER ( mclu =    10 )
      INTEGER mhit
      PARAMETER ( mhit =    10 )
      INTEGER mstack
      PARAMETER ( mstack =  30 )
C.
C.    nelem:              Number of 'struck' modules
C.    jelem:              Volume # of 'struck' module
C.
C.    nstack:             Number of neighbours still on the stack
C.    jstack(istack):     Volume # of stack entry 'istack'
C.
C.    indx_stack(istack): Index of stack member
C.
C.                        index = ilevel for stack member with 'hit'
C.                        index = index(iseed) - 1 for member without 'hit'
C. 
C.    nhit(nclu):         Number of neighbours in cluster's hit list
C.    jhit(ihit,nclu):    Volume # of entry on hit list
C.
      INTEGER nelem,      jelem(mhit)
      INTEGER nstack,     jstack(mstack)
      INTEGER nhit(mclu), jhit(mhit,mclu)
C.
      INTEGER index, ilevel
      INTEGER indx_stack(mstack)
C.
      INTEGER i, ii, j, l, n, nclu, iseed
C.
      INTEGER jnbr
      INTEGER nbr(max_hexagon)
c.
      LOGICAL first / .TRUE. /
C.
      DATA ilevel/ 0 /
C.
C.    (Note: n_fngr(1,i) is i module itself)
C.
      If(first)then
        first = .FALSE.
        Do i = 1, max_hexagon
           nbr(i) = 0
           Do j = 2, Nn
              If(n_fngr(j,i).ne.0)nbr(i) = nbr(i) + 1
           Enddo
        Enddo
      Endif
C.
      nclu = 0
C.
      Do 1000 i = 1, nelem
C.
         iseed = jelem(i)
C.
         If(nclu.gt.0)then
           Do n = 1, nclu
             Do l = 1, nhit(n)
                If(iseed.eq.jhit(l,n))goto 1000
             Enddo
           Enddo
         Endif
C.
         If(nclu.ge.mclu)goto 999
         nclu = nclu + 1
C.
         nstack = 0
         index  = ilevel
C. 
         nhit(nclu) = 1
         jhit(nhit(nclu),nclu) = iseed
C.
  100    Continue
C.
C. Loop over all nearest neighbours 
C.                       (Note: n_fngr(1,iseed) is iseed module itself)
C.
         Do 10 j = 1, nbr(iseed)
C.
            jnbr = n_fngr(j+1,iseed)
C.
C. Loop over all members already in the hit list
C.
            Do l = 1, nhit(nclu)
               If(jnbr.eq.jhit(l,nclu))goto 10
            Enddo
C.
C. Loop over all members already on the stack
C.
            Do l = 1, nstack
               If(jnbr.eq.jstack(l))goto 10
            Enddo 
C.
C.     If the neighour is not already on the hit list or on the stack:
C.
C.  ** Put it on the hit list AND on the stack      if it has a  'hit' **
C.  ** Put it                     on the stack ONLY if it has no 'hit' **
C.  ** Put it                     on the stack ONLY if seed-index > 0  **
C. 
            Do ii = 1, nelem
C.
              If(jnbr.eq.jelem(ii))then
C.
                If(nhit(nclu).ge.mhit)goto 999
                nhit(nclu) = nhit(nclu) + 1
                jhit(nhit(nclu),nclu) = jnbr
C.
                If(nstack.ge.mstack)goto 999
                nstack = nstack + 1
                jstack(nstack) = jnbr
                indx_stack(nstack) = ilevel
C.
                goto 10
C.
              Endif
C.
            Enddo
C.
            If(nstack.ge.mstack)goto 999
            If(index.gt.0)then
              nstack = nstack + 1
              jstack(nstack) = jnbr
              indx_stack(nstack) = index - 1
            Endif
C.
   10    Continue                             ! End Loop over neighbours
C.
         If(nstack.gt.0)then
           iseed = jstack(nstack)
           index = indx_stack(nstack)
           nstack = nstack - 1
           goto 100
         Endif
C.
 1000 Continue
C.
      RETURN 
C.
  999 Continue
C.
      Write(lout,*)' *** Problem in GENCLU *** for event: ',ievent
      Write(lout,*)' Number of clusters nclu (<=10)       ',nclu
      Write(lout,*)' Number of elements in cluster (<=10) ',nhit(nclu)
      Write(lout,*)' Size of search stack (<=30)          ',nstack
C.
      RETURN 
      END
C.
