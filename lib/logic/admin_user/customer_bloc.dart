import 'admin_user_bloc.dart';

class CustomerBloc extends AdminUserBloc {
  CustomerBloc({required super.repository}) : super(role: 'CUSTOMERS');
}
