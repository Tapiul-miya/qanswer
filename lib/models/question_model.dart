class QuestionModel {
  String? id;
  String subject;
  String question;
  String answer;

  QuestionModel({
    this.id,
    required this.subject,
    required this.question,
    required this.answer,
  });

  // 🔄 Convert Firestore → Model
  factory QuestionModel.fromMap(Map<String, dynamic> map, String docId) {
    return QuestionModel(
      id: docId,
      subject: map['subject'] ?? '',
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
    );
  }

  // 🔄 Convert Model → Firestore
  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'question': question,
      'answer': answer,
    };
  }
}