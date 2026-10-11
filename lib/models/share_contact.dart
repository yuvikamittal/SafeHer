/// A contact that live location can be shared with.
class ShareContact {
  final String id;
  final String name;
  final String relation;
  bool isSelected;

  ShareContact({
    required this.id,
    required this.name,
    required this.relation,
    required this.isSelected,
  });
}
