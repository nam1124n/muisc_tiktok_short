import 'package:equatable/equatable.dart';
import 'package:login_flutter/domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

// 1. Trạng thái nghỉ ngơi ban đầu (chưa làm gì)
class AuthInitial extends AuthState {}

// 2. Trạng thái Đang tải (UI sẽ hiện vòng tròn Loading)
class AuthLoading extends AuthState {}

// 3. Trạng thái Thành công (UI sẽ nhảy sang màn Home)
class AuthSuccess extends AuthState {
  final UserEntity user;
  const AuthSuccess(this.user);

  @override
  List<Object> get props => [user];
}

// 4. Trạng thái Lỗi (UI sẽ văng lên cái thông báo đỏ)
class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);

  @override
  List<Object> get props => [message];
}
