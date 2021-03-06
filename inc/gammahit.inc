C variables for gammahit ntuple
C recoil_hit_ENDV, flag for each event, equals 1 if recoild reached ENDV
C num_bgos_hit, num of BGOs triggered during event
C e_bgos_total, summed energy deposited in all BGOs
C num_bgo_first/second, ID# of leading/second leading BGO
C e_bgo_first/second, energy deposited in leading/second leading BGO
C pair_productions, number of pairs produced in event
C _ab, adding back of nearest neighbours used to calculate
C adjacency_matrix, element (i,j) = 1 if BGOs i and j are neighbours

      REAL e_bgos_total, e_bgo_first, e_bgo_second,
     + e_bgo_first_ab, e_bgo_second_ab, gammatof, gammatofp, e0_conv
      INTEGER recoil_hit_ENDV, num_bgos_hit, num_bgo_first, 
     + num_bgo_second, pair_productions, num_bgos_hit_ab,
     + num_bgo_first_ab, num_bgo_second_ab, adjacency_matrix(30,30),
     + isBGO, isLaBr3, det_mate(30)
      COMMON /GAMMAHIT/ recoil_hit_ENDV, num_bgos_hit, e_bgos_total,
     + num_bgo_first, e_bgo_first, num_bgo_second, e_bgo_second,
     + pair_productions, num_bgos_hit_ab, 
     + num_bgo_first_ab, e_bgo_first_ab, num_bgo_second_ab,
     + e_bgo_second_ab, gammatof, gammatofp, e0_conv,
     + isBGO, isLaBr3, det_mate
