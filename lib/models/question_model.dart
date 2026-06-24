class QuestionModel {
  String? id;
  String subject;
  String question;
  String answer;
  String className;

  QuestionModel({
    this.id,
    required this.subject,
    required this.question,
    required this.answer,
    required this.className,
  });

  factory QuestionModel.fromMap(
      Map<String, dynamic> map, String docId) {
    return QuestionModel(
      id: docId,
      subject: map['subject'] ?? '',
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      className: map['class'] ?? '1',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'question': question,
      'answer': answer,
      'class': className,
    };
  }
}