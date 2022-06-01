import 'package:lunch_me/data/tables.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipe_info.freezed.dart';

@freezed
class RecipeInfo with _$RecipeInfo {
  const factory RecipeInfo({
    String? name,
    Source? type,
    String? url,
    String? image,
    String? imagePhoto,
    String? contentPhoto,
  }) = _RecipeInfo;
}
