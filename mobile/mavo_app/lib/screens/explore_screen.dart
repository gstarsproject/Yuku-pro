import 'package:flutter/material.dart';
import '../services/mavo_api.dart';
import '../theme/mavo_theme.dart';

class ExploreScreen extends StatefulWidget {
  final String initialPillar;
  const ExploreScreen({super.key, this.initialPillar = ''});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}
class _ExploreScreenState extends State<ExploreScreen> {
  final search = TextEditingController();
  late String pillar;
  @override
  void initState() {
    super.initState();
    pillar = widget.initialPillar;
  }
  late Future<List<Map<String, dynamic>>> results = MAVOApi.services();
  void reload() => setState(() => results = MAVOApi.services(query: search.text, pillar: pillar));
  @override
  void didUpdateWidget(covariant ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPillar != widget.initialPillar) {
      pillar = widget.initialPillar;
      results = MAVOApi.services(query: search.text, pillar: pillar);
    }
  }
  @override
  void dispose() { search.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => SafeArea(child: Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(20,20,20,12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Explore', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800,color:MAVOColors.navy)),
      const SizedBox(height:4), const Text('Temukan kreator, layanan, dan pengalaman.',style:TextStyle(color:MAVOColors.muted)),
      const SizedBox(height:16),
      TextField(controller:search,textInputAction:TextInputAction.search,onSubmitted:(_)=>reload(),decoration:InputDecoration(hintText:'Cari layanan...',prefixIcon:const Icon(Icons.search),suffixIcon:IconButton(onPressed:reload,icon:const Icon(Icons.arrow_forward)))),
      const SizedBox(height:12),
      Wrap(spacing:8,children:[_filter('Semua',''),_filter('Friend','FRIEND'),_filter('Experience','EXPERIENCE'),_filter('Pro','PRO')]),
    ])),
    Expanded(child:FutureBuilder<List<Map<String,dynamic>>>(future:results,builder:(context,snapshot){
      if(snapshot.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
      if(snapshot.hasError)return _message('Belum bisa memuat layanan. Coba lagi.',reload);
      final items=snapshot.data??[];
      if(items.isEmpty)return _message('Belum ada layanan yang dipublikasikan.',reload);
      return RefreshIndicator(onRefresh:()async{reload();},child:ListView.separated(padding:const EdgeInsets.fromLTRB(20,4,20,24),itemCount:items.length,separatorBuilder:(_,__)=>const SizedBox(height:12),itemBuilder:(context,index)=>_ServiceCard(item:items[index])));
    })),
  ]));
  Widget _filter(String label,String value)=>ChoiceChip(label:Text(label),selected:pillar==value,onSelected:(_){pillar=value;reload();});
  Widget _message(String message,VoidCallback retry)=>Center(child:Padding(padding:const EdgeInsets.all(28),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.search_off_rounded,size:42,color:MAVOColors.muted),const SizedBox(height:12),Text(message,textAlign:TextAlign.center),const SizedBox(height:12),OutlinedButton(onPressed:retry,child:const Text('Coba lagi'))])));
}
class _ServiceCard extends StatelessWidget {
 final Map<String,dynamic> item;
 const _ServiceCard({required this.item});
 @override
 Widget build(BuildContext context){
  final price=item['priceAmount']??0;
  final verified=item['verificationStatus']=='VERIFIED';
  return Material(color:Colors.white,borderRadius:BorderRadius.circular(17),child:InkWell(borderRadius:BorderRadius.circular(17),onTap:()=>showModalBottomSheet<void>(context:context,isScrollControlled:true,showDragHandle:true,builder:(context)=>_ServiceDetails(item:item)),child:Container(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Row(children:[CircleAvatar(backgroundColor:const Color(0xFFEAF1FF),child:Text(((item['providerName']??'Y').toString().isEmpty ? 'Y' : (item['providerName']??'Y').toString().substring(0,1).toUpperCase()),style:const TextStyle(color:MAVOColors.navy,fontWeight:FontWeight.bold))),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(item['providerName']??'MAVO Provider',style:const TextStyle(fontWeight:FontWeight.bold)),Text(item['categoryName']??'Layanan',style:const TextStyle(fontSize:12,color:MAVOColors.muted))])),if(verified)const Icon(Icons.verified,color:MAVOColors.blue,size:19)]),
   const SizedBox(height:14),Text(item['title']??'Layanan',style:const TextStyle(fontSize:16,fontWeight:FontWeight.bold)),const SizedBox(height:5),Text(item['description']??'',maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:MAVOColors.muted)),const SizedBox(height:12),
   Row(children:[Expanded(child:Text('${item['city']??'Online'} · ${item['priceUnit']??''}',style:const TextStyle(fontSize:12,color:MAVOColors.muted))),Text('Rp ${price.toString()}',style:const TextStyle(color:MAVOColors.blue,fontWeight:FontWeight.w800))]),
  ]))));
 }
}

class _ServiceDetails extends StatefulWidget {
 final Map<String,dynamic> item;
 const _ServiceDetails({required this.item});
 @override
 State<_ServiceDetails> createState() => _ServiceDetailsState();
}

class _ServiceDetailsState extends State<_ServiceDetails> {
 bool _booking = false;

 Future<void> _book() async {
  final now = DateTime.now();
  final date = await showDatePicker(
   context: context,
   initialDate: now.add(const Duration(days: 1)),
   firstDate: DateUtils.dateOnly(now),
   lastDate: now.add(const Duration(days: 365)),
  );
  if (date == null || !mounted) return;
  final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
  if (time == null || !mounted) return;
  final mode = await showDialog<String>(
   context: context,
   builder: (dialogContext) => AlertDialog(
    title: const Text('Pilih metode booking'),
    content: const Text('Instant Booking langsung menuju pembayaran. Request Booking menunggu persetujuan provider.'),
    actions: [
     TextButton(onPressed: () => Navigator.pop(dialogContext, 'REQUEST'), child: const Text('Request Booking')),
     FilledButton(onPressed: () => Navigator.pop(dialogContext, 'INSTANT'), child: const Text('Instant Booking')),
    ],
   ),
  );
  if (mode == null || !mounted) return;
  final start = DateTime(date.year, date.month, date.day, time.hour, time.minute);
  final duration = (widget.item['durationMinutes'] as num?)?.toInt() ?? 60;
  final end = start.add(Duration(minutes: duration));
  setState(() => _booking = true);
  try {
   await MAVOApi.createBooking(
    serviceId: widget.item['id'].toString(),
    startsAt: start,
    endsAt: end,
    bookingMode: mode,
   );
   if (!mounted) return;
   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(mode == 'INSTANT'
      ? 'Booking dibuat. Lanjutkan pembayaran dari Booking Saya.'
      : 'Permintaan booking dikirim ke provider.'),
   ));
   Navigator.pop(context);
  } catch (e) {
   if (mounted) ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
   );
  } finally {
   if (mounted) setState(() => _booking = false);
  }
 }

 @override
 Widget build(BuildContext context) {
  final item = widget.item;
  final name=(item['providerName']??'MAVO Provider').toString();
  final title=(item['title']??'Layanan').toString();
  final description=(item['description']??'Belum ada deskripsi.').toString();
  final price=item['priceAmount']??0;
  final verified=item['verificationStatus']=='VERIFIED';
  return SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(22,8,22,28),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
   Text(title,style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800,color:MAVOColors.navy)),
   const SizedBox(height:12),
   Row(children:[CircleAvatar(backgroundColor:const Color(0xFFEAF1FF),child:Text(name.isEmpty?'M':name.substring(0,1).toUpperCase(),style:const TextStyle(color:MAVOColors.navy,fontWeight:FontWeight.bold))),const SizedBox(width:10),Expanded(child:Text(name,style:const TextStyle(fontWeight:FontWeight.w700))),if(verified)const Icon(Icons.verified,color:MAVOColors.blue)]),
   const SizedBox(height:16),
   Text(description,style:const TextStyle(height:1.5,color:MAVOColors.ink)),
   const SizedBox(height:14),
   Text('Kategori: \${item['categoryName']??'Layanan'}'),
   Text('Pilar: \${item['pillar']??'Marketplace'}'),
   Text('Lokasi: \${item['city']??'Online'}'),
   Text('Harga: Rp \${price.toString()} \${item['priceUnit']??''}',style:const TextStyle(fontWeight:FontWeight.w800,color:MAVOColors.blue)),
   const SizedBox(height:18),
   const Text('Jadwal akan diperiksa kembali oleh server sebelum booking dibuat. Jangan melakukan pembayaran di luar alur resmi MAVO.',style:TextStyle(fontSize:12,color:MAVOColors.muted,height:1.4)),
   const SizedBox(height:14),
   SizedBox(width:double.infinity,child:FilledButton(
    onPressed: _booking ? null : _book,
    child: _booking ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Buat Booking'),
   )),
   const SizedBox(height:6),
   SizedBox(width:double.infinity,child:TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Tutup'))),
  ])));
 }
}
