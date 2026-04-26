class QuestionModel {
  int? id;
  String subject;
  String question;
  String answer;

  QuestionModel({this.id, required this.subject, required this.question, required this.answer});

  Map<String, dynamic> toMap() {
    return {'id': id, 'subject': subject, 'question': question, 'answer': answer};
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      id: map['id'],
      subject: map['subject'],
      question: map['question'],
      answer: map['answer'],
    );
  }
}
