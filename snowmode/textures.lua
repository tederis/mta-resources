snowmodeStarted = false

local textures = { 
	--Снег простой
	single = "textures/single/single.mtacrmat",
	singleLOD = "textures/single/singleLOD.mtacrmat",
	--Проселочная дорога
	offroad = "textures/single/offroad.mtacrmat",
	offroad90 = "textures/single/offroad90.mtacrmat",
	offroad_crossT = "textures/single/offroad_crossT.mtacrmat",
	offroad_crossT90 = "textures/single/offroad_crossT90.mtacrmat",
	offroad_crossX = "textures/single/offroad_crossX.mtacrmat",
	offroad_end = "textures/single/offroad_end.mtacrmat",
	--Железная дорога
	railroad = "textures/single/railroad.mtacrmat",
	railroad2 = "textures/single/railroad2.mtacrmat",
	--Скала
	stone = "textures/single/stone.mtacrmat",
	stone2 = "textures/single/stone2.mtacrmat",
	stone3 = "textures/single/stone3.mtacrmat",
	stone4 = "textures/single/stone4.mtacrmat",
	stone5 = "textures/single/stone5.mtacrmat",
	stone6 = "textures/single/stone6.mtacrmat",
	--Тропинка
	footpath = "textures/single/footpath.mtacrmat",
	--Дороги
	road = "textures/single/road.mtacrmat",
	road2 = "textures/single/road2.mtacrmat",
	--road3 = "textures/single/road3.mtacrmat",
	--Аэропорт
	aero = "textures/single/aero.mtacrmat",
	aero2 = "textures/single/aero2.mtacrmat",
	--Бордюры
	bord = "textures/single/bord.mtacrmat",
	bord2 = "textures/single/bord2.mtacrmat",
	bord3 = "textures/single/bord3.mtacrmat",
	--Бетон
	concrete = "textures/single/concrete.mtacrmat",
	--Лед
	ice = "textures/single/ice.mtacrmat",
	--Парковка
	parking = "textures/single/parking.mtacrmat",
	--Плотина
	plotina = "textures/single/plotina.mtacrmat",
	--Тротуар
	trot = "textures/single/trot.mtacrmat",
	trot2 = "textures/single/trot2.mtacrmat",
	trot3 = "textures/single/trot3.mtacrmat",
	trot4 = "textures/single/trot4.mtacrmat",
	trottile = "textures/single/trottile.mtacrmat",
	trottileLOD = "textures/single/trottileLOD.mtacrmat",
	special = "textures/single/special.mtacrmat",

	blend = "textures/blend/blend.mtacrmat",
	noise = "textures/other/noise.mtacrmat",
 }

----------------------------------------------
--Простые текстуры
----------------------------------------------
local shaders = {
 { texture = "single",
  --Трава
  "grass_128hv2", "road13", "les", "travalight1", "yardgrass1", "oldgrs2_bld_citygrass", "oldgrass2", "ruscount_grass", "grass1_a", "desertstones256", "smechanii_les", "grass_128hv", "grass_4", "trava", "my_grass_1", "ryz_xvoinles", "ryz_kystarnland", "ryz_xvoinles_polyana", "ryz_xvoinles_kystlmix1", "ryz_xvoinles_grassmix", "desertgryard256", "desgreengrass", "smechanii_lesgrass", "land_p-g", "ryz_kystarnland_grassmix", "ryzozero_2048grassbeach", "bysaevo_dsplace1024", "ryz_polegrassed", "ryz_poleclear", "yardgrass_rmap", "new_ryazan_les", "new_ryazan_lesgrass", "new_ryazan_lesgrs_out", "new_ryazan_lesgrs_in", "love_ground1", "love_grass", "love_xolmik", "ryz_xvoinles_supermix", "myhreg2", "makronko", "zem", "myhreg", "zemlya", "sandland", "pesok_dno2", "13kardon_sandland", "13kardon_rockgarden", "sh185b", "sv_zemla", "znam_grass_bada", "grass_g-b", "perroad_03", "nn_oldrgrass", "nn_oldrpesok", "edovo_dom4_grassflowersdark", "edovo_doubledom_grass256hd", "nn_klad_grassgrnd", "edovo_coundom_gryadka", "edovo_coundom_grass2", "new_asfblend_oldgrass2", "yardles_rmap", "drydirt", "setunka_dnograsslesmix", "gryadka_04", "gryadka_03", "gryadka_02", "gryadka_01", "newgrassbrnles2", "special_ground", "bat_rodn_sheb_w", "bat_rodn_shebn", "oldg2_rw_brn", "grsdrysand_rockmix", "ruscount_tailing_cliff3", "ruscount_obochina", "ruscount_roadsandconn", "country_road1", "grass_128hv3", "scheben_correct", "sch_grs_angl", "sch_grs_line", "border_grass2", "combul_grass", "perroad_02", "ruscount_roadsandconnt", "ruscount_oboles", "roadraz_grassblend", "crete_walls13", "beton_03_1024", "roadraz_out_sndrd", "roadraz_betblend", "country_rush", "perroad_2a", "schebenmy2", "mahmuril_mtratyar", "kart_blokprx", "nn_oldrasfdamage", "chkal_02", "reg_grdigr", "dirtogr", "dirt01", "dirt3", "dirttoas", "dirttoas2", "dtatg", "gr2gr2", "ground2", "ryzozero_asftosand", "bysaevo_magschrdmix", "byssch_flwdirt", "bysaevo_magrd_kolokdirt", "ruscount_kanblend_newles", "rockstarmem_tail", "toy02", "rush_park_08", "asf-zem", "ground", "ground1", "kolhoz", "arz_trot_3", "znam_grass_bad", "park_3pam1", "dorogax", "nn_oldrpesok2", "nn_klad_jama", "beton_0002", "tesla_roadasf", "tesla_asf", "chuck_zem", "bat_bank_tol", "bx_rooftop_2", "astoground", "cncrt_07", "leg_byxlotraxtex6", "razvjazka_rog", "pzu_road_01", "wood_up",
  --Трава с бордюрами
  "border_grass",
  --Канавы и ямы
  "smechanii_leskanblend", "ruscount_kanavablend", "smechanii_waterfall", "smechanii_les_gkb", "prud_bereg", "ryz_sandholewall", "ruscount_roadcrashed", "ruscount_road1_crash", "park_kanav1", "park_kanav2", "park_kanav3", "prud_dno2", "ruscount_kanbolmix", "kanava2oldgrass", "kanava",
  --Переходы
  "svr_grasstosand", "kart_perexod", "road_by_ank_bok", "ryzozero_sandsmooth_grsmx2", "ryzozero_sandsmooth_grsmix", "ryzozero_sandsmooth_snd2mix", "ryzozero_sandsmooth", "newgrassbrnles", "bysaevo_grasssandmix", "ryz_polegrassed_grsmix", "ryz_poleclear_grsmix", "prud_dno1", "grsdrysand", "ruscount_bolotograssmix", "ruscount_boloto", "grasshv2_smeshblnd", "plyazh_travablnd", "zemlya_tr", "land_p-g2", "land_a-g", "sh185c", "oldgrass2blendles", "grass_cpark", "setunka_dnotoforest", "gravel_grassmix", "road7_blend", "special_groundmix", "special_groundmix2", "land_p-a", "land_a-p", "pesok_per_new",
  --Асфальт
  "sv_asph2", "kart_beton2", "znam_asfalt", "znam_road3", "mp_conc_g",
  --Песок и гравий
  "pesok_2", "sv_peso4eg2", "new_sand2", "bysaevo_sch_sandplace", "setunka_dnodirt", "setunka_dnotograss", "shebenka_map", "new_betonrailgravel", "new_betonrailggrsmix", "ryz_sandholetile", "sand", "gravel",
  --Пляж
  "ws_drysand", "ws_wetdryblendsand", "ryzozero_sandsmooth_undwmix", "pesok_dno1", "ws_drysand2grass",
  --Крыши плоские
  "ws_mh_commonroof4_big", "rus_roof", "nj01_rooftop1", "crete_roof1", "trash", "krisha", "auto_roof", "krishatk", "roof_flat1", "roof", "sa_roof", "medicsubsta_roof", "1195_rooffloor", "8bit_roof3", "dom11", "ws_corrugateddoor1", "trashpol", "misc01", "rubiroid2", "tunn_concplane", "metal_corrigated20", "mahmutil_mg_roof", "roof2", "ritm_wall4", "ws_rooftarmac1", "dom004", "roof01l256", "altyn_roof", "lodsevas_dom4n_roof", "loddom188-1_roof", "ruberoid", "cover", "kart_beton", "rub", "oof1", "chpc-brd", "krov_zhl", "88b38a9e", "roof_sc4", "roof_gaz", "crete_roof2", "nn_oldrroof", "edovo_doubledom_krisha", "nfh_roof", "mah_office_eroof", "bmetall",
  --Крыши со скатом
  "dom007", "kalin_roof", "pod_roof", "top", "sta4_roof", "st2_cherepic", "metall_roof", "shifer", "prommetallroof", "shifer_roof_b", "trainstation_4", "42", "34", "41", "rubiroid", "krovel_gelezo_rgav", "sl_clayroof01", "colis_green_roof2", "rus_mtlroof_n", "ngtu_roof", "metal_roof", "rus_mtlroof", "antey_roof1", "sevas14_tile", "crete_schiffer3", "sad_krysha", "colis_blue_roof", "up_metal_red", "shifer_2", "shifer_1", "covered", "metch", "love_roof", "shif5", "shif2", "shif3", "kor_blueolder_shiffer", "kor_yellow_roof", "kor_lelia_shiffer", "kor_ryberoidroof", "rush_dom9_shifer", "bat_oleg_krysha", "krysha", "rush_kafe_krysha", "batdkshifer", "rush_dom5_shifer", "rush_dom5_krysha", "rush_razor8_chpc-brd", "rush_razor8_krysha", "bat_bank_krysha", "bat_bank_kletka", "bat_admin_cher", "bat49_riflenka", "mtl_roof_green", "bat_ugol_krysha", "batvtkrysha", "bat_orlov_shifer", "rush_dom7_shifer", "rush_dom7_krysha", "bat_kot_krysha", "bat_vdpo_krysha", "bataskrs", "batastol", "bat_serkrysha", "bat_voen_shif", "roof_gar_rog", "roof_shif", "shiferok", "w_doski3", "roof_a", "gelezo_krov", "kreml_roof", "nn_oldrgelezo_krov", "edovo_autovokzal_roofmetall", "edovo_provatedom_shifer", "edovo_katelnya_shifer", "edovo_coundom_shifer", "edovo_coundom_darkmetall", "edovo_coundom_domtextyre3", "edovo_coundom_roofrustmetall", "edovo_coundom_shellmap", "edovo_coundom_rustmetall2", "nn_cerkov_krishagreen", "vlnity_plech_02_1024", "st3_shifer", "kor_steelroof", "kor_dachnegg_shiffer", "kor_shiffers", "dom036", "mp_prisonroof_128", "mp_greyrust_128", "up_4_dvor", "up_dvor", "up_metal_blue", "up_metal_green", "shifer_3", "up", "izba_up", "saray_up1", "saray_up2", "shifer90", "up_4_dvor90", "bat_rodn_krysha", "bat_cer_krysha", "nfh_mroof", "peshruf32256hi copy", "metplkr", "shifmag", "krishapod", "roof4", "iz_krr",
  --Прочее
  "znam_grass_good", "znam_trib01", "slozhno2", "slozhno", "floor_burned", "doska2", "magily_mramor", "klad_xolmik", "up_lestnitsa", "tikva", "metall", "water3", "platform_floor",

   "nastil_spl", "garel_back", "4_dog_up_03" },
 { texture = "single", properties = { SparkleSize = 12 }, "reg_gr2gr", "pod12et", "zem_trop", "zem_trop2" },
 { texture = "singleLOD",
  --LOD'ы плоских крыш
  "lodtykran_9e_roof", "lod_pandom_top", "admin88top", "1_top", "2_top", "lodmah_house1_roof", "lod_mahmarket2_roof", "lod_mahoff_roof", "lodmah_house3_roof", "lodstolovka_fr", "lod_5etagke_roof", "lod_ammu_top", "houselod2", "lod_azs_top", "lod_anashan_top", "5e_roof", "loddom3_roof", "lodpln4", "halod2", "rus_rooflod", "lodmalyshroof_txd", "lod_tc_roof", "lod_rusrap_roof", "altyn_roof", "jun_lod2", "lodgen_five1_roof", "lod_boiler_roof", "lodgengrge_roof", "lodsevas_dom186-3_roof", "sevas6_4", "lodsevas_dom8_roof", "lodsevas_kanna_roof", "lodsevas_club_roof", "lodsevas_napitki_roof", "lod162k1t", "loddianup2", "lod_market2", "lodtran2", "lodprosp_dom141_top", "rgv4lod_school_top", "rgv4lod_gas_top", "rgv4lod_prodshop_top", "jelezo", "lod_tykoff_top",
  --LOD'ы крыш со скатом
  "lodtykkor_roof", "loddom3p2_roof", "lodsta4_roof", "lodmkhru_roof", "lodpln6", "ti_rnd4", "lodproof", "lodment_top", "lodmah_house2_roof", "kalinin_three_roof", "lod_ckp_roof", "lod_drumth_roof" --[[Крыша + асфальт в НГТУ]], "lod_ngtu_roof", "lod_dom192_roof", "lod_dom194_roof", "lodsev2xd_roof", "lodantey_front", "lodantey_back", "lodantey_roof", "lodsevas_dom14_roof", "lodsevas_orgteh_roof", "lodap_roof", "lodap3_roof", "lodap2_roof", "rgv4lod_fishshop_top", "back", "rgv4lod_hb_top", "rgv4lod_house2_top", "rgv4lod_house9_top", "rgv4lod_krnvnk_top", "rgv4lod_church_top", "rgv4lod_zhil_top", "rgv4lod_house7_top", "rgv4lod_house12_top", "rgv4lod_house11_top", "rgv4lod_house13_top", "rgv4lod_myh_top", "rgv4lod_house4_top", "rgv4lod_house6_top", "rgv4lod_house5_top", "rgv4lod_house3_top", "rgv4lod_house1_top", "metalroof003a", "schiffer", "build_2_base_tile_2", "build_3_base", "shell_map", "lodkor_almaz1", "lodkor_blueold1", "lodkor_yellow1", "lodkor_voron1", "lodkor_zek1", "lodkor_myxin1", "lodkor_alex1", "lodkor_pu1", "lodkor_lapa1", "lodkor_swed1", "lodkor_semen1", "lodkor_kydel1", "lodkor_new1", "loddachnegg1", "lodmaxim1", "lodlelia1", "lodkor_vasia1", "lod_prisontower_top", "lodgarmel_right", "lodgarmel_left", "lodgar3", "lodgar2", "lodgar4", "lodgar1", "lod_arzroad4l", "lod13rayonbulvar", "lodanashanland",
  --Трава, земля
  "rgv4lod_mel_ground", "gryda", "grass2", "c8a3683a", "lod13endplane", "lodmbp2", "lodplatoprom1", "lod_scrd6", "lodgar5" },
  { texture = "offroad",
  --Обычная проселочная
  "ruscount_rdsandgrass", "ruscount_rdsandgrsmix", "ruscount_roadsand", "new_ryazan_lesdirt_rd", "new_ryazan_ldirt_rdmix", "ryzozero_sandsth_2_lesgrs", "ryzozero_sandsth_2_grs", "ryzozero_sandsmooth_road", "ryzozero_sandsmooth_roadlm", "ryzozero_sandsth_roadlms", "ryz_xvoinles_dirtroad", "ryz_xvoinles_dirtroadsndmix", "road_country", "village_road", "ruscount_roadsand_gray", "ruscount_rdsandgray_mix", "road_sel", "road_5", "land_p-g_vil", "oldgrass2_droad", "roadraz_sndlesrdmix", "roadraz_sndrd", "smechles_dirttrack", "ruscount_dirtsandroad", "pov_r_s", "ryzozero_sandsth_2_les", "ruscount_roadsand_bmix", "smechles_dirtsandtrk" },
 { texture = "offroad90", "ruscount_dirtroad_", "ruscount_kanava_bdr" },
 { texture = "offroad_crossT", "ruscount_rdsndgrajunc", "ruscount_rdsand_junc", "road_country2", "ruscount_rdsndgrayjunc" },
 { texture = "offroad_crossT90", "ruscount_dirtroad_cross" },
 { texture = "offroad_crossT", properties = { gUVRotAngle = 1.57 * 2 }, "ryzozero_sandsth_roadcross" },
 { texture = "offroad_crossX", "smechles_dirttrack_gross" },
 { texture = "offroad_end", "13rayon_croad", "ruscount_rdsandstart", "tupigg", "oldgrass2_drdend", "ruscount_dirtroad_end"},
 { texture = "offroad_end", properties = { gUVRotAngle = 1.57 * 2 }, "smechles_dirttrack_endles", "ruscount_rdsandgrsasf" },
 { texture = "offroad_end", properties = { gUVRotAngle = 1.57 }, "village_road2", "road_by_ank_sandrdblend", "ryzozero_connsandrd", "ruscount_obochina_dr" },
 { texture = "railroad", "rails_map" },
 { texture = "railroad2", "new_betonrailway" },
 { texture = "stone", "stone3", "undw_stone", "global_rocktype1", "ruscount_newcliff" },
 { texture = "stone2", "rockwall_lbrn2", "ruscount_newcliff_les", "ruscount_tailing_cliff_rel" },
 { texture = "stone3", "newlesbrnrock", "global_grassrock_hardblend" },
 { texture = "stone4", "brn_rockgrass_grid" },
 { texture = "stone5", "newrockbrndsand", "global_rockrubblemix" },
 { texture = "stone6", "brn_rs_gs_grid" },
 { texture = "stone6", properties = { gUVRotAngle = 1.57 }, "brn_les_rock_grass" },
 { texture = "footpath", "park_road1", "park_plitka2", "park_road3", "bysaevo_tropinka", "bat_adpl", "pzu_road_02", "road_6" },
 { texture = "footpath", properties = { gUVRotAngle = 1.57 }, "tr2", "edovo_coundom_path", "zemla" },
 
 { texture = "road", properties = { gUVScale = 0.57, gUVPosition = 0.62 }, "nn_road_3", "nn_road_3b" },
 
 { texture = "road", "sa_centerblendnew", "road3", "road2", "ruscount_shebenroad", "ruscount_shbnsnd_mix", "ruscount_road1_spec1", "kart_asph", "kart_start", "road1", "new_asf_pulse", "sa_pulseblendnew", "nn_road_2", "ruscount_roadline", "ruscount_road1", "edovo_asphalt", "road_02", "road_02_draco", "rog2gar_roadblank", "rog2gar_roadcrash3", "rog2gar_roadcrash2", "rog2gar_roadcrash1", "rog2gar_blendasfsnd", "ruscount_roadsand_big", "ruscount_roadpulse", "nn_road_4" }, --Центр
 
 { texture = "road", properties = { gUVScale = 0.98, gUVPosition = 0.94 }, "new_asf_center" },
 
 { texture = "road", properties = { gUVRotAngle = 1.57 }, "ruscount_obochina_sbnrd", "ruscount_shebenrd_asfmix" }, --Центр
 
 { texture = "road", properties = { gUVScale = 4, gUVPosition = 0.43 }, "mahmutil_mostrd4" }, --Мост Южный
 { texture = "road", properties = { gUVScale = 2, gUVPosition = 0.43 }, "country_road2", "wolv_roads", "arz_road_clear" }, --Около Арзамаса
 { texture = "singleLOD", properties = { Alpha = 0 }, "wgush1", "wjet2", "arz_zebra", "road9", "znam_grass_wht" },
 { texture = "road2", properties = { gUVScale = 0.7, gUVRotAngle = 1.57 }, "road7", "auto_asphalt1", "conchev_64hv", "concrete_64hv", "metpat64", "trainstation_floor", "30", "50", "ws_carparknew2", "pereezd_map1", "wolv_dr_2", "road_by_ank_3", "road_by_ank_2", "road_by_ank_1", "perroad_01_new", "perroad_01", "bat_pa-ba", "perroad_05", "per_1-as", "bat_ga-ba", "grnd_asphalt_mix", "schebenmy1", "schebenmy3", "arz_per_2", "wolv_roads_cross", "znam_road2", "znam_asfalt", "wolv_roads_per", "kart_asph2", "kart_asph3", "pzu_road_03", "nn_klad_road", "nn_klad_asf1", "edovo_coundom_path2", "edovo_oldtratyar", "edovo_katelnya_asf", "edovo_katelnya_pavetile", "edovo_dirtroad", "edovo_asfaltvc", "edovo_asphalt_pxod2", "edovo_autovokzal_asf", "nn_oldrgrayasfalt", "chkal_05", "asfasv3", "asph", "graviy", "asphalt", "astoas", "bowattoboir", "dirtoas3", "wolv_dr_0b", "wolv_dr_0", "wolv_dr_1", "wolv_dr_1r", "wolv_dr_1l", "rog2gar_garrdblend", "ruscount_road1_place", "bysaevo_school_dorogka", "bysaevo_koster_plita", "bysaevo_schrddrgmix", "bysaevo_school_asf", "klad_tropka", "new_tratyar", "dt_road2", "auto_asphalt2", "perroad_77", "sa_dtroad", "ind_road_b", "ind_road_crossing", "vstavka", "pesok_new", "nn_road_1", "road4", "new_asf_place", "asfroad_ygdmix2", "ravine_4", "ravine_5", "ravine_6", "ravine_7", "park_road2", "mp_gravfloor_g", "mp_concfloor" },
 { texture = "parking", "auto_asphalt3", "road10", "ws_carpark1", "road10_spec" },
 { texture = "trot", "tratyar",  "wolv_trot", "nn_tratyar4x" },
 { texture = "trot2", "new_tratgrassmix" },
 { texture = "trot3", "arz_trot_2" },
 { texture = "trottile", "road5", "road8", "road5a", "road14" },
 { texture = "bord", properties = { gUVRotAngle = 1.57 }, "mahmutil_mt_border" },
 { texture = "bord2", properties = { gUVRotAngle = 1.57 * 2 }, "road6" },
 { texture = "bord2", "road16", "wb_parebrik", "bat_bord", },
 { texture = "bord3", "border", "bord01", "znam_border", "edovo_doubledom_bordur", "nn_oldrparebrik" },
 { texture = "ice", properties = { SparkleSize = 8 }, "pesok_2", "pesok_5", "waterclear256" },
 { texture = "plotina", "plotina01" },
 { texture = "aero", properties = { SparkleSize = 12 }, "bat_aer_vpp" },
 { texture = "aero2", properties = { SparkleSize = 12 }, "bat_aer_zalivka" },
 { texture = "special", properties = { SparkleSize = 12 }, "ryazan_specialbysend" } }
 
----------------------------------------------
--Замена текстур с сохранением альфа канала
----------------------------------------------
local alphaColors = { 
 --Деревья и кустарники
 "wow", "wow2", "veg_bushred", "veg_bushgrn", "veg_bush2", "veg_bush3red", "flowers", "grass", "tree_lodpaper_der2", "tree_lodeubeech1", "tree_lodderevo1", "tree_lodwillow", "lentisk", "willow", "beechalder", "pberk2", "lindenlf", "berktak", "kastanbrn", "tree_lodpaper_der1", "tree_lodlinden", "tree_lodfikovnik", "tree_lodkastan", "bushwt", "bushwall", "genbush", "potato", "spikeybushfull", "hackberry", "veglod_pine5", "pbranch", "pbranch(1)", "espeb", "poplar2", "lodbushshrub11", "lod_poplar2veg", "huntre_tree_leaf", "lodh_leaftree_root", "lodh_leaftree_vol", "lodh_leaftree_med", "lodh_leaftree_big", "kb_ivy2_256", "cj_plant", "mugopine1", "mugopine2", "pine", "veg_lodpinee1", "veglod_pinekust", "veglod_pine2", "veglod_pine3", "veglod_pine4", "oriental", "jed_de3", "newtreeleaves128", "lod_e1", "norway", "veg_lodpine1", "veg_lodpine2", "veg_lodpine5", "veg_lodpine4", "veg_lodpine3", "lupinprototype", "flowersbaikal", "firtopx", "juni", "lodeu_veg2", "lodeu_veg1", "galder", "lod_papernew3", "lod_papernew2", "lod_paperarz", "abies", "abies3", "orien2", "lod_pinebig7", "lod_norwpine4", "lod_norwpine3", "lod_norwpine1", "lod_norwpine2", "vetvicky", "lodh_pinetree3", "lodh_pinetree2", "lodh_pinetree1", "lodh_pinesmall", "lodh_pineangled", "huntre_tree_pine", "obranch", "hornlf", "f437c114", "brg_recko1", "trees_vetkagreen5", "woak", "poplar", "holly", "elm", "klengreen", "bg-tree003leavesarecol",
--Трава
 "rus_grasstype1", "rus_bigorgangeflower", "rus_grasstype3", "rus_grasstype2", "rus_whiteflower_ingrass", "rus_grasstype4_flowers", "borchevik", "lopux_list", "hunter_moregrass", "hunter_flowers2", "hunter_flowers", "hunter_longgrass", "hunter_bush", "hunter_bush2", "polehighgrass1", "fialkiflowers", "4ertopolox", "grass1", "krapiva_list", "svekla", "tomato", "luchog", "flowert", "starflower3", "starflower3yel", "starflower2", "starflower3prpl", "starflower2wht", "edovo_coundom_flower", "edovo_coundom_flora", "byssch_flower5", "byssch_flower4", "byssch_flower3", "byssch_flower2", "byssch_flower1", "lopux_koluchka", "apat_flowers",
 --Прочее
 "powerlinewire", "provoda", "electrica1", "rush_cep", "electro_pda2", "fire_escfloor", "derevo_krov", "particleskid",

"railing", "kolosya_rog" }
 
----------------------------------------------
--Наложение текстуры(бленд)
----------------------------------------------
local snowBlend = { 
 "bruschatka2", "bat_arb_plitka", "plitkas", "mozaika", "stupenki", "bord098zv5", "bat_bank_mozaika", "batvtmozaik", "bat_admin_plitka1", "estacade_under", "road11", "industrial_betonhq", "beton_29_1", "sl_pavement", "gb_ramirez_roof02", "ind_trainyard_kerb", "concrete_podval2", "wood_plank7_cor", "zel_krs", "cratetop128", "rush_park_06", "rush_stone", "rushplit", "bat_diezil", "doorstep", "ston_stena_ch_14", "bat_admin_plitka2", "bord", "black_metal", "grnd_asphalt_mp", "avt_stup", "ston_stena_ch", "bet_bord", "ston_stuccowall3_iov", "opora", "bet_brus", "colis_brusch", "ter01", "combul_stairs", "combul_crete", "nick_fzabor3", "nick_fzabor", "nick_fzabor2", "crete_walls8_01", "apat_stupenki", "apat_crete", "concrete_new", "concrete_quad", "green", "brusch", "tsokol_3", "perekr_brusch", "bender_stupenki", "altyn_wall_2", "colis_stupenki", "bruschpink", "veh_moskvitch_01", "asphalt_new", "wall_04", "cj_corrigated", "fasad_brusch", "bender_brusch", "etfire_bruschatka", "etfire_mramor", "etfire_stupenki", "znam_knv", "znam_trib05", "znam_trib04", "znam_trib02", "znam_trib03", "add1_b", "kirmet_10", "crete_pol_brown_1_512", "56_hz6", "colis_brusch3", "font_mram2_5", "fancy_slab128", "rusrap_stupenki", "bruschatka", "crete_walls7_a", "park_3_1", "02", "01", "gaydar_plitka", "gaydar_lesenka", "wood_zabor_iov", "park_zabx", "park_zabw", "perekr_heli", "kart_metal", "kart_ograda", "kart_safezone", "kart_blok2", "kart_ograda2", "trash1", "edovo_betonplita", "edovo_dom_d14_plitkat", "edovo_autovokzal_fencewall", "det_ploshadka2", "toy01", "nn_oldrkrishakids", "nn_oldrgrayconcrete", "ston_floor_03", "cr-dc2", "b", "pol3", "concretemanky", "pli5etst", "00_wall_3012_1", "ground_brick_parker2", "rocktq128", "cj_bark", "tree_stub1", "rockstarmem_mramor", "colis_green_roof", "st_1", "dom141_07", "st_2", "rus_stupenki", "rus_tran_arnd_1", "koper_stupenki", "bg-tree003trunk", "fasad_stupenup", "seno", "chuck_durak", "blane_mog", "mraz_mog", "bat_tir_shifer", "bat_skam", "bat_bank_beton", "batdktol", "batdkmcher2", --[["concrete",]] "zpli", "stup", "wood_018", "shif", "pol", "lest4", "pli4", "klumb", "roadraz_betbase", "mahmutil_rechotka", "korobka1", "zabor_1", "toy03", "car", "49", "wh1", "wh2", "woo2", "woo1", "jel", "kra", "zel", "mahmutil_mostcrete", "ygd_shpali1", "ygd_shpali2", "wood_plank7", "wood_1", "l2_detal_01", "beton_plit_05_1", "13kardon_balka", "izba_lz", "dom051", "sh_road2", "sh_bridge_dop", "crete_border_02", "sh_fonari", "sh_bridge_opora2", "sh_bridge_opora1", "kart_pokr2", "kart_pokr1", "dirt64b", "gen_log", "mp_kerb_s", "box_texturepage", "cj_crates", "cj_slatedwood", "mp_diner_wall", "metall_flat256", "tilefloor021a", "sciana16", "woodfloor007a", "angar" }
 
local upSnow = {
	"huntre_tree_pine",
	"wow2",
	
	--Скамейки
	"bat_skam", "skam_zhel",
	"telepole128",
    
    "mahmutil_mostbalk",
    "road12",
    "rgd_mostblk",
    "concrete",
    "15polennica",
    "brevna2",
    
    "hunter_balk", "hunter_woodstair",
    
    "spruce1",
    
    "monster92tyre64",
    "metall2", "ab_wallpaper02","angar_door", "tem1_body2", "beton_body", "tupic", "rusfrid2", "53", "3", "wall_2",
	
	"wow", "wow2", "veg_bushred", "veg_bushgrn", "veg_bush2", "veg_bush3red", "flowers", "grass", "tree_lodpaper_der2", "tree_lodeubeech1", "tree_lodderevo1", "tree_lodwillow", "lentisk", "willow", "beechalder", "pberk2", "lindenlf", "berktak", "kastanbrn", "tree_lodpaper_der1", "tree_lodlinden", "tree_lodfikovnik", "tree_lodkastan", "bushwt", "bushwall", "genbush", "potato", "spikeybushfull", "hackberry", "veglod_pine5", "pbranch", "pbranch(1)", "espeb", "poplar2", "lodbushshrub11", "lod_poplar2veg", "huntre_tree_leaf", "lodh_leaftree_root", "lodh_leaftree_vol", "lodh_leaftree_med", "lodh_leaftree_big", "kb_ivy2_256", "cj_plant", "mugopine1", "mugopine2", "pine", "veg_lodpinee1", "veglod_pinekust", "veglod_pine2", "veglod_pine3", "veglod_pine4", "oriental", "jed_de3", "newtreeleaves128", "lod_e1", "norway", "veg_lodpine1", "veg_lodpine2", "veg_lodpine5", "veg_lodpine4", "veg_lodpine3", "lupinprototype", "flowersbaikal", "firtopx", "juni", "lodeu_veg2", "lodeu_veg1", "galder", "lod_papernew3", "lod_papernew2", "lod_paperarz", "abies", "abies3", "orien2", "lod_pinebig7", "lod_norwpine4", "lod_norwpine3", "lod_norwpine1", "lod_norwpine2", "vetvicky", "lodh_pinetree3", "lodh_pinetree2", "lodh_pinetree1", "lodh_pinesmall", "lodh_pineangled", "huntre_tree_pine", "obranch", "hornlf", "f437c114", "brg_recko1", "trees_vetkagreen5", "woak", "poplar", "holly", "elm", "klengreen", "bg-tree003leavesarecol",
}

function startWinter ( )
	if snowmodeStarted then 
		return
	end
	
	snowmodeStarted = true
	
	-- Подготавливаем текстуры
	loadedTextures = { }
	
	for name, path in pairs ( textures ) do
		if fileExists ( path ) then
			loadedTextures [ name ] = dxCreateTexture ( path )
			
			if not loadedTextures [ name ] then
				outputDebugString ( "При создании текстуры " .. name .. " произошла ошибка", 1 )
			end
		else
			outputDebugString ( "Файла " .. path .. " не существует", 1 )
		end
	end
 
	readyShaders = { }
	
	-- Simple add shader
	for _, worldtextures in pairs ( shaders ) do
		local texture = loadedTextures [ worldtextures.texture ]
	
		if texture then
			local shader, technique = dxCreateShader ( "shaders/shader.fx", 0, 3000, false, "world,object" )
			if technique ~= "tec0" then
				outputChatBox ( "S1O: Ваш видеоадаптер не поддерживает рекомендованный режим. Для получения дополнительных сведений обратитесь к администрации сервера." )
				return
			end
   
			setShaderPrelight ( shader )
   
			if worldtextures.properties then
				for property, value in pairs ( worldtextures.properties ) do
					dxSetShaderValue ( shader, tostring ( property ), value )
				end
			end
			dxSetShaderValue ( shader, "Tex", texture)
			dxSetShaderValue ( shader, "noiseTexture", textures.noise )
            
            for _, name in ipairs ( worldtextures ) do
				engineApplyShaderToWorldTexture ( shader, name )
			end
   
			table.insert ( readyShaders, shader )
		else
			outputDebugString ( "Текстуры не существует", 1 )
		end
	end
 
	-- Alpha replace shader
	readyShaders.alphashader, alphatechnique = dxCreateShader ( "shaders/shaderalphablend.fx", 0, 3000, false, "world,object" )
	if alphatechnique ~= "tec0" then
		outputChatBox ( "S2A: Ваш видеоадаптер не поддерживает рекомендованный режим. Для получения дополнительных сведений обратитесь к администрации сервера." )
		return
	end
	dxSetShaderValue ( readyShaders.alphashader, "Tex", loadedTextures.trottileLOD )

	setShaderPrelight ( readyShaders.alphashader )

	for _, name in ipairs ( alphaColors ) do
		engineApplyShaderToWorldTexture ( readyShaders.alphashader, name )
	end  
 
	-- Blend shader
	readyShaders.blendshader, blendtechnique = dxCreateShader ( "shaders/blend.fx", 0, 3000, false, "world,object" )
	dxSetShaderValue ( readyShaders.blendshader, "Tex2", loadedTextures.trottile )
	dxSetShaderValue ( readyShaders.blendshader, "BlendTex", loadedTextures.blend )

	setShaderPrelight ( readyShaders.blendshader )

	for _, name in ipairs ( snowBlend ) do
		engineApplyShaderToWorldTexture ( readyShaders.blendshader, name )
	end
	
	outputDebugString ( "upshader")
	
	IceFiller.create ( )

	--Сообщение
	outputChatBox ( "Вы всегда можете отключить падающий снег, отправив комманду /offsnow", 255, 255, 0, true )
end

function stopWinter ( )
	if not snowmodeStarted then 
		return
	end
	
	snowmodeStarted = false
	
	for name, texture in pairs ( loadedTextures ) do
		destroyElement ( texture )
	end
	
	loadedTextures = nil

	for _, shader in ipairs ( readyShaders ) do
		engineRemoveShaderFromWorldTexture ( shader, "*" )
		destroyElement ( shader )
	end
 
	engineRemoveShaderFromWorldTexture ( readyShaders.alphashader, "*" )
	destroyElement ( readyShaders.alphashader )
 
	engineRemoveShaderFromWorldTexture ( readyShaders.blendshader, "*" )
	destroyElement ( readyShaders.blendshader )
	
	IceFiller.destroy ( )
 
	readyShaders, loadedTextures = nil, nil
end

addCommandHandler ( "sn109m", 
	function ( )
		if snowmodeStarted then
			stopWinter ( )
		else
			startWinter ( )
		end
	end 
)

addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )
		startWinter ( )
	end
, false )