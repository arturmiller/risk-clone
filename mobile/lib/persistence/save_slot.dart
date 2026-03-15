import 'package:objectbox/objectbox.dart';

@Entity()
class SaveSlot {
  @Id()
  int id = 0;

  @Property()
  String gameStateJson = '';

  @Property()
  int turnNumber = 0;

  @Property()
  String timestamp = '';

  SaveSlot({
    this.id = 0,
    this.gameStateJson = '',
    this.turnNumber = 0,
    this.timestamp = '',
  });
}
