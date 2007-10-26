# IBM(c) 2007 EPL license http://www.eclipse.org/legal/epl-v10.html
#ibmleds,tab, mfg,prod_id,led_id,desc
package xCAT::data::ibmleds;

my %x3755_leds = (
0x0065=>'Dimm 6',
0x0011=>'VRM',
0x00d9=>'Alert',
0x0030=>'CPU1',
0x0032=>'CPU3',
0x00ca=>'Dimm 27',
0x0075=>'PCI 6',
0x00c1=>'Dimm 18',
0x0019=>'NMI',
0x0040=>'UNKNOWN',
0x0067=>'Dimm 8',
0x000f=>'RAID',
0x00c4=>'Dimm 21',
0x0057=>'Fan 8',
0x00d0=>'ServeRAID 8k Batt',
0x0069=>'Dimm 10',
0x000e=>'BOARD',
0x00c3=>'Dimm 20',
0x00cf=>'Dimm 32',
0x006f=>'Dimm 16',
0x0054=>'Fan 5',
0x00cd=>'Dimm 30',
0x0000=>'FAULT',
0x0014=>'FAN',
0x00c8=>'Dimm 25',
0x006c=>'Dimm 13',
0x0061=>'Dimm 2',
0x00c2=>'Dimm 19',
0x0074=>'PCI 5',
0x006a=>'Dimm 11',
0x00b9=>'CPU2_BOARD',
0x0047=>'UNKNOWN',
0x0050=>'Fan 1',
0x0072=>'PCI 3',
0x00c5=>'Dimm 22',
0x00c0=>'Dimm 17',
0x0070=>'PCI 1',
0x00c9=>'Dimm 26',
0x0006=>'CNFG',
0x006b=>'Dimm 12',
0x00d8=>'BK_Blue',
0x0068=>'Dimm 9',
0x00bb=>'CPU4_BOARD',
0x00c6=>'Dimm 23',
0x0031=>'CPU2',
0x0010=>'CPU',
0x00b8=>'CPU1_BOARD',
0x0056=>'Fan 7',
0x0063=>'Dimm 4',
0x00b0=>'HTX',
0x0001=>'LOCATION',
0x000b=>'SEER',
0x0013=>'DASD',
0x00cb=>'Dimm 28',
0x0052=>'Fan 3',
0x0064=>'Dimm 5',
0x001c=>'TEMP',
0x00c7=>'Dimm 24',
0x0060=>'Dimm 1',
0x00d1=>'ServeRAID 8k Err',
0x0073=>'PCI 4',
0x0015=>'MEM',
0x0003=>'INFO',
0x006e=>'Dimm 15',
0x0071=>'PCI 2',
0x00ba=>'CPU3_BOARD',
0x00ce=>'Dimm 31',
0x001b=>'OVERSPEC',
0x0041=>'UNKNOWN',
0x006d=>'Dimm 14',
0x0051=>'Fan 2',
0x001e=>'SP',
0x0066=>'Dimm 7',
0x0053=>'Fan 4',
0x0055=>'Fan 6',
0x0033=>'CPU4',
0x00cc=>'Dimm 29',
0x0020=>'PCI',
0x0062=>'Dimm 3',
);

%leds = (
  "2,14" => \%x3755_leds,
);
