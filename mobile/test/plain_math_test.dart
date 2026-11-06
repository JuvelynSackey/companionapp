import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/assistant/widgets/message_text.dart';

void main() {
  test('the LaTeX Gemini sent in a real tutor answer becomes plain maths', () {
    expect(
      plainMath(r'binary 1011 equals $(1\times8) + (0\times4) + (1\times2) + (1\times1)$, which gives 11'),
      'binary 1011 equals (1 × 8) + (0 × 4) + (1 × 2) + (1 × 1), which gives 11',
    );
  });

  test('common commands, fractions, roots, text and powers', () {
    expect(plainMath(r'$\frac{3}{4}$'), '3/4');
    expect(plainMath(r'$\sqrt{16} = 4$'), '√(16) = 4');
    expect(plainMath(r'$x \leq 10$ and $y \geq 2$'), 'x ≤ 10 and y ≥ 2');
    expect(plainMath(r'$2^{10} = 1024$'), '2^10 = 1024');
    expect(plainMath(r'$\text{GPA} \approx 3.2$'), 'GPA ≈ 3.2');
    expect(plainMath(r'$$a \div b$$'), 'a ÷ b');
  });

  test('money and ordinary text are left alone', () {
    expect(plainMath(r'Tickets cost $10 and $20.'), r'Tickets cost $10 and $20.');
    expect(plainMath('No maths here: 3 + 4 = 7'), 'No maths here: 3 + 4 = 7');
  });
}
