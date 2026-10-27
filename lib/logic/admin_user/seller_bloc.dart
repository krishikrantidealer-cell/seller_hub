import '../../core/models/seller.dart';
import 'admin_user_bloc.dart';

class SellerBloc extends AdminUserBloc {
  SellerBloc({required super.repository}) : super(role: 'SELLERS');

  List<SellerProfile> get sellerProfiles =>
      state.users.map((u) => SellerProfile.fromAdminUser(u)).toList();
}
