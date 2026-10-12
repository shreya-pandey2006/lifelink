const kBloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
const kCities = ['Ghaziabad', 'Noida', 'Delhi', 'Lucknow', 'Patna', 'Mumbai'];
const kUrgencyLabels = {1: 'Normal', 2: 'Urgent', 3: 'Critical'};
const kDonatesTo = {
  'O-': ['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+'], 'O+': ['O+', 'A+', 'B+', 'AB+'], 'A-': ['A-', 'A+', 'AB-', 'AB+'],'A+': ['A+', 'AB+'],
  'B-': ['B-', 'B+', 'AB-', 'AB+'], 'B+': ['B+', 'AB+'], 'AB-': ['AB-', 'AB+'], 'AB+': ['AB+'],
};

List<String> donorsFor(String recipient) =>
    kBloodGroups.where((g) => kDonatesTo[g]!.contains(recipient)).toList();
    const kUrgencyDescriptions = {
  1: 'Scheduled within 24-48 hours', 2: 'Required within 6-12 hours', 3: 'Immediate broadcast to all nearby donors',
};