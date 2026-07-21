// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'result_vo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResultVo _$ResultVoFromJson(Map<String, dynamic> json) => ResultVo(
      code: (json['code'] as num?)?.toInt() ?? -1,
      msg: json['msg'] as String? ?? "N/A",
      obj: json['obj'],
    );

Map<String, dynamic> _$ResultVoToJson(ResultVo instance) => <String, dynamic>{
      'code': instance.code,
      'msg': instance.msg,
      'obj': instance.obj,
    };
