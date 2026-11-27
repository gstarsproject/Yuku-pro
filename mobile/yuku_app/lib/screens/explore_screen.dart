import 'package:flutter/material.dart';
import '../services/yuku_api.dart';
import '../theme/yuku_theme.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}
class _ExploreScreenState extends State<ExploreScreen> {
  final search = TextEditingController();
  String pillar = '';
  late Future<List<Map<String, dynamic>>> results = YukuApi.services();
  void reload() => setState(() => results = YukuApi.services(query: search.text, pillar: pillar));
  @override
  void dispose() { search.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => SafeArea(child: Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(20,20,20,12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Jelajahi MAVO', style: TextStyle(fontSize:27,fontWeight:FontWeight.w900,color:MavoColors.midnight)),
      const SizedBox(height:4), const Text('Temukan orang, layanan, dan pengalaman baru.',style:TextStyle(color:MavoColors.muted,fontSize:12)),
      const SizedBox(height:16),
      TextField(controller:search,textInputAction:TextInputAction.search,onSubmitted:(_)=>reload(),decoration:InputDecoration(hintText:'Cari layanan atau provider...',prefixIcon:const Icon(Icons.search),suffixIcon:IconButton(onPressed:reload,icon:const Icon(Icons.arrow_forward)))),
      const SizedBox(height:12),
      SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[_filter('Semua',''),const SizedBox(width:8),_filter('FRIEND','FRIEND'),const SizedBox(width:8),_filter('EXPERIENCE','EXPERIENCE'),const SizedBox(width:8),_filter('PRO','PRO')])),
    ])),
    Expanded(child:FutureBuilder<List<Map<String,dynamic>>>(future:results,builder:(context,snapshot){
      if(snapshot.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
      if(snapshot.hasError)return _message('Belum bisa memuat layanan. Coba lagi.',reload);
      final items=snapshot.data??[];
      if(items.isEmpty)return _message('Belum ada layanan yang dipublikasikan.',reload);
      return RefreshIndicator(onRefresh:()async{reload();},child:ListView.separated(padding:const EdgeInsets.fromLTRB(20,4,20,24),itemCount:items.length,separatorBuilder:(_,__)=>const SizedBox(height:12),itemBuilder:(context,index)=>_ServiceCard(item:items[index])));
    })),
  ]));
  Widget _filter(String label,String value)=>ChoiceChip(label:Text(label),selected:pillar==value,showCheckmark:false,selectedColor:MavoColors.violetSoft,backgroundColor:Colors.white,side:BorderSide(color:pillar==value?MavoColors.violet.withValues(alpha:.25):const Color(0xFFEAE8F0)),labelStyle:TextStyle(color:pillar==value?MavoColors.violet:MavoColors.muted,fontWeight:FontWeight.w800,fontSize:11),onSelected:(_){setState(()=>pillar=value);reload();});
  Widget _message(String message,VoidCallback retry)=>Center(child:Padding(padding:const EdgeInsets.all(28),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.search_off_rounded,size:42,color:YukuColors.muted),const SizedBox(height:12),Text(message,textAlign:TextAlign.center),const SizedBox(height:12),OutlinedButton(onPressed:retry,child:const Text('Coba lagi'))])));
}
class _ServiceCard extends StatelessWidget {
 final Map<String,dynamic> item;
 const _ServiceCard({required this.item});
 @override
 Widget build(BuildContext context){
  final price=item['priceAmount']??0;
  final verified=item['verificationStatus']=='VERIFIED';
  return Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20),border:Border.all(color:const Color(0xFFEDEBF3)),boxShadow:[BoxShadow(color:MavoColors.midnight.withValues(alpha:.035),blurRadius:16,offset:const Offset(0,5))]),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Row(children:[CircleAvatar(backgroundColor:const Color(0xFFEAF1FF),child:Text((item['providerName']??'Y').toString().substring(0,1).toUpperCase(),style:const TextStyle(color:YukuColors.navy,fontWeight:FontWeight.bold))),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(item['providerName']??'MAVO Provider',style:const TextStyle(fontWeight:FontWeight.bold)),Text(item['categoryName']??'Layanan',style:const TextStyle(fontSize:12,color:YukuColors.muted))])),if(verified)const Icon(Icons.verified,color:YukuColors.blue,size:19)]),
   const SizedBox(height:14),Text(item['title']??'Layanan',style:const TextStyle(fontSize:16,fontWeight:FontWeight.bold)),const SizedBox(height:5),Text(item['description']??'',maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:YukuColors.muted)),const SizedBox(height:12),
   Row(children:[Expanded(child:Text('${item['city']??'Online'} · ${item['priceUnit']??''}',style:const TextStyle(fontSize:12,color:YukuColors.muted))),Text('Rp ${price.toString()}',style:const TextStyle(color:YukuColors.blue,fontWeight:FontWeight.w800))]),
  ]));
 }
}
