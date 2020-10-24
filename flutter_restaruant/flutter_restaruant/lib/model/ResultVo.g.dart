// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ResultVo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResultVo _$ResultVoFromJson(Map<String, dynamic> json) {
  return ResultVo(
    code: json['code'] as int,
    msg: json['msg'] as String,
    obj: json['obj'],
  );
}

Map<String, dynamic> _$ResultVoToJson(ResultVo instance) => <String, dynamic>{
      'code': instance.code,
      'msg': instance.msg,
      'obj': instance.obj,
    };
