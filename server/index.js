const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const multer = require('multer');
const pdfParse = require('pdf-parse');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 4000;
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 6 * 1024 * 1024,
  },
});

const openRouterApiKey = process.env.OPENROUTER_API_KEY;
const openRouterUrl = 'https://openrouter.ai/api/v1/chat/completions';
const defaultModel = process.env.OPENROUTER_MODEL || 'openai/gpt-4o-mini';

global.resumeContent = global.resumeContent || null;
global.askedQuestions = global.askedQuestions || [];

const fallbackSystemPrompt = `You are a professional job interviewer.

- Ask one question at a time
- After the user answers:
  1. Give feedback including strengths and improvements
  2. Ask the next question
- Maintain a professional tone
- After the final question, give a score out of 10
- Return strict JSON with keys: question, feedback, score, shouldEnd, summary`;

app.use(cors());
app.use(express.json({ limit: '10mb' }));

app.get('/', (_, res) => {
  res.send('Backend working');
});

app.get('/health', (_, res) => {
  res.json({
    ok: true,
    resumeLoaded: Boolean(global.resumeContent),
  });
});

app.post('/api/upload-resume', upload.single('file'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({
      error: 'Missing resume file in request.',
    });
  }

  try {
    const parsedText = await extractResumeText(req.file);
    if (!parsedText) {
      return res.status(400).json({
        error: 'Unable to extract text from the uploaded resume.',
      });
    }

    global.resumeContent = buildResumeContext(parsedText, req.file.originalname);
    global.askedQuestions = [];

    return res.json({
      ok: true,
      fileName: req.file.originalname,
      summary: global.resumeContent,
    });
  } catch (error) {
    console.error('Resume upload failed:', error);
    return res.status(500).json({
      error: error.message || 'Resume processing failed.',
    });
  }
});

app.post('/api/chat', async (req, res) => {
  const { messages, system } = req.body ?? {};

  if (!openRouterApiKey) {
    return res.status(500).json({
      error: 'Missing OPENROUTER_API_KEY in server environment.',
    });
  }

  if (!Array.isArray(messages) || messages.length === 0) {
    return res.status(400).json({
      error: 'Request body must include a non-empty messages array.',
    });
  }

  const previousQuestions = messages
    .filter((message) => message.role === 'assistant')
    .map((message) => String(message.content || '').trim())
    .filter(Boolean);

  global.askedQuestions = previousQuestions;

  const isFirstQuestion = previousQuestions.length === 0;
  const effectiveSystem =
    typeof system === 'string' && system.trim().length > 0
      ? system
      : fallbackSystemPrompt;

  const smartSystemPrompt = `
${effectiveSystem}

You are a professional AI interviewer.

STRICT RULES:
1. NEVER repeat a question that was already asked:
${previousQuestions.join('\n') || 'No previous questions yet.'}

2. The first interview question must always be:
"Tell me about yourself."

3. If a resume is available:
- From the second question onwards
- ALL questions MUST be based on the resume

Resume:
${global.resumeContent || 'No resume provided'}

4. Ask only ONE question at a time.
5. Keep questions natural, realistic, and human-like.
6. Return strict JSON only with keys: question, feedback, score, shouldEnd, summary.
7. If this is the first question, set question to "Tell me about yourself." exactly.
8. If this is not the first question and resume exists, every next question must clearly come from the resume context.
9. Never output a question that appears in the previous-question list.
`;

  try {
    const response = await fetch(openRouterUrl, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${openRouterApiKey}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': 'http://localhost:4000',
        'X-Title': 'Welp.Ai',
      },
      body: JSON.stringify({
        model: defaultModel,
        messages: [
          {
            role: 'system',
            content: smartSystemPrompt,
          },
          ...messages,
        ],
      }),
    });

    const data = await response.json();

    if (!response.ok) {
      return res.status(response.status).json({
        error:
          data?.error?.message ||
          data?.message ||
          'OpenRouter request failed.',
      });
    }

    const reply = data?.choices?.[0]?.message?.content;
    if (typeof reply !== 'string' || reply.trim().length === 0) {
      return res.status(502).json({
        error: 'OpenRouter returned an empty reply.',
      });
    }

    const parsedReply = safeParseReply(reply);
    const nextQuestion = String(parsedReply.question || '').trim();

    if (isFirstQuestion && nextQuestion && nextQuestion !== 'Tell me about yourself.') {
      return res.json({
        reply: JSON.stringify({
          ...parsedReply,
          question: 'Tell me about yourself.',
        }),
      });
    }

    if (nextQuestion && global.askedQuestions.includes(nextQuestion)) {
      return res.json({
        reply: JSON.stringify({
          ...parsedReply,
          question: global.resumeContent
              ? 'Walk me through a resume achievement that best shows your impact.'
              : 'Can you elaborate more on your previous experience?',
        }),
      });
    }

    return res.json({ reply });
  } catch (error) {
    console.error('OpenRouter request failed:', error);
    return res.json({
      reply: JSON.stringify({
        question:
          'Tell me about a project where you solved a difficult problem under pressure.',
        feedback:
          'Demo fallback: the AI service is temporarily unavailable, so this mock interviewer is keeping the session running. Focus on structure, impact, and measurable results in your next answer.',
        score: 8,
        shouldEnd: false,
        summary:
          'Fallback response used because the upstream AI service was unavailable.',
      }),
    });
  }
});

function safeParseReply(reply) {
  try {
    return JSON.parse(reply);
  } catch (_) {
    return {
      question: reply,
      feedback: '',
      score: 0,
      shouldEnd: false,
      summary: '',
    };
  }
}

function normalizeWhitespace(text) {
  return text.replace(/\s+/g, ' ').trim();
}

async function extractResumeText(file) {
  const fileName = (file.originalname || '').toLowerCase();

  if (file.mimetype === 'application/pdf' || fileName.endsWith('.pdf')) {
    const pdfData = await pdfParse(file.buffer);
    return normalizeWhitespace(pdfData.text || '');
  }

  return normalizeWhitespace(file.buffer.toString('utf8'));
}

function buildResumeContext(text, fileName) {
  const trimmed = normalizeWhitespace(text);
  const limited = trimmed.slice(0, 2200);
  return `Uploaded resume: ${fileName}
Resume summary:
${limited}`;
}

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});
