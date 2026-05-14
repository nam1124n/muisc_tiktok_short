const DEFAULT_SUNO_BASE_URL = 'https://api.sunoapi.org';
const DEFAULT_SUNO_MODEL = 'V5';

export default {
  async fetch(request, env) {
    const corsHeaders = buildCorsHeaders(env);

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    try {
      const url = new URL(request.url);
      const path = normalizePath(url.pathname);

      if (request.method === 'GET' && path === '/health') {
        return jsonResponse({ ok: true, service: 'suno-worker' }, 200, corsHeaders);
      }

      if (
        request.method === 'POST' &&
        (path === '/callback' || path === '/suno/callback' || path === '/api/suno/callback')
      ) {
        await readJson(request);
        return jsonResponse({ ok: true }, 200, corsHeaders);
      }

      if (
        request.method === 'POST' &&
        (path === '/' || path === '/generate' || path === '/api/generate')
      ) {
        return handleGenerate(request, env, corsHeaders);
      }

      if (request.method === 'GET') {
        const taskId = readTaskId(path);
        if (taskId) {
          return handleGenerationStatus(taskId, env, corsHeaders);
        }
      }

      return jsonResponse({ error: 'Not found' }, 404, corsHeaders);
    } catch (error) {
      return jsonResponse(
        { error: error instanceof Error ? error.message : String(error) },
        500,
        corsHeaders,
      );
    }
  },
};

async function handleGenerate(request, env, corsHeaders) {
  if (!env.SUNO_API_KEY) {
    return jsonResponse({ error: 'SUNO_API_KEY is not configured' }, 500, corsHeaders);
  }

  const input = await readJson(request);
  const prompt = stringValue(input.prompt).trim();
  if (!prompt) {
    return jsonResponse({ error: 'prompt is required' }, 400, corsHeaders);
  }

  const userId = stringValue(input.userId || input.user_id || 'guest_user');
  const callbackUrl = stringValue(
    input.callBackUrl ||
      input.callbackUrl ||
      env.SUNO_CALLBACK_URL ||
      `${new URL(request.url).origin}/api/suno/callback`,
  ).trim();

  const payload = {
    customMode: Boolean(input.customMode ?? false),
    instrumental: Boolean(input.instrumental ?? false),
    model: stringValue(input.model || env.SUNO_MODEL || DEFAULT_SUNO_MODEL),
    prompt,
  };

  if (callbackUrl) {
    payload.callBackUrl = callbackUrl;
  }

  const response = await fetch(`${sunoBaseUrl(env)}/api/v1/generate`, {
    method: 'POST',
    headers: sunoHeaders(env),
    body: JSON.stringify(payload),
  });

  const upstream = await readUpstreamJson(response);
  if (!response.ok || isSunoError(upstream)) {
    const status = response.ok ? 422 : response.status;
    return jsonResponse(normalizeSunoError(upstream, status), status, corsHeaders);
  }

  const data = upstream.data && typeof upstream.data === 'object' ? upstream.data : upstream;
  const taskId = stringValue(data.taskId || data.task_id || data.id);
  if (!taskId) {
    return jsonResponse({ error: 'Suno did not return taskId', upstream }, 502, corsHeaders);
  }

  return jsonResponse(
    {
      taskId,
      task_id: taskId,
      userId,
      user_id: userId,
      prompt,
      status: normalizeStatus(data.status || 'processing'),
      provider: 'suno-api',
      outputCount: numberValue(data.outputCount || data.output_count, 2),
      tracks: [],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    },
    202,
    corsHeaders,
  );
}

async function handleGenerationStatus(taskId, env, corsHeaders) {
  if (!env.SUNO_API_KEY) {
    return jsonResponse({ error: 'SUNO_API_KEY is not configured' }, 500, corsHeaders);
  }

  const response = await fetch(
    `${sunoBaseUrl(env)}/api/v1/generate/record-info?taskId=${encodeURIComponent(taskId)}`,
    {
      method: 'GET',
      headers: sunoHeaders(env),
    },
  );

  const upstream = await readUpstreamJson(response);
  if (!response.ok || isSunoError(upstream)) {
    const status = response.ok ? 422 : response.status;
    return jsonResponse(normalizeSunoError(upstream, status), status, corsHeaders);
  }

  const data = upstream.data && typeof upstream.data === 'object' ? upstream.data : upstream;
  const tracks = buildTracks(taskId, data);
  const now = new Date().toISOString();

  return jsonResponse(
    {
      taskId,
      task_id: taskId,
      userId: stringValue(data.userId || data.user_id || ''),
      user_id: stringValue(data.userId || data.user_id || ''),
      prompt: stringValue(data.prompt || tracks[0]?.prompt || ''),
      status: normalizeStatus(data.status || 'processing'),
      provider: 'suno-api',
      outputCount: Math.max(numberValue(data.outputCount || data.output_count, 2), tracks.length),
      tracks,
      createdAt: normalizeDate(data.createTime || data.createdAt || data.created_at) || now,
      updatedAt: normalizeDate(data.updateTime || data.updatedAt || data.updated_at) || now,
    },
    200,
    corsHeaders,
  );
}

function buildTracks(taskId, data) {
  const sunoData = Array.isArray(data.response?.sunoData)
    ? data.response.sunoData
    : Array.isArray(data.sunoData)
      ? data.sunoData
      : Array.isArray(data.data)
        ? data.data
        : [];

  return sunoData.map((track, index) => {
    const audioUrl = firstString([
      track.sourceAudioUrl,
      track.source_audio_url,
      track.audioUrl,
      track.audio_url,
      track.sourceStreamAudioUrl,
      track.source_stream_audio_url,
      track.streamAudioUrl,
      track.stream_audio_url,
    ]);
    const streamAudioUrl = firstString([
      track.sourceStreamAudioUrl,
      track.source_stream_audio_url,
      track.streamAudioUrl,
      track.stream_audio_url,
      audioUrl,
    ]);

    return {
      id: stringValue(track.id || `${taskId}_${index}`),
      taskId,
      task_id: taskId,
      variantIndex: index,
      variant_index: index,
      title: stringValue(track.title || `AI Audio ${index + 1}`),
      prompt: stringValue(track.prompt || data.prompt || ''),
      audioUrl,
      audio_url: audioUrl,
      streamAudioUrl,
      stream_audio_url: streamAudioUrl,
      imageUrl: firstString([
        track.sourceImageUrl,
        track.source_image_url,
        track.imageUrl,
        track.image_url,
      ]),
      image_url: firstString([
        track.sourceImageUrl,
        track.source_image_url,
        track.imageUrl,
        track.image_url,
      ]),
      durationSeconds: numberValue(track.duration || track.durationSeconds || track.duration_sec, 0),
      duration_sec: numberValue(track.duration || track.durationSeconds || track.duration_sec, 0),
      provider: 'suno-api',
      modelName: stringValue(track.modelName || track.model_name || data.type || DEFAULT_SUNO_MODEL),
      model_name: stringValue(track.modelName || track.model_name || data.type || DEFAULT_SUNO_MODEL),
      tags: readTags(track.tags || data.tags || ''),
      createdAt: normalizeDate(track.createTime || track.createdAt || data.createTime),
      created_at: normalizeDate(track.createTime || track.createdAt || data.createTime),
    };
  });
}

function readTaskId(path) {
  const match = path.match(/^\/(?:api\/)?generations\/([^/]+)$/);
  return match ? decodeURIComponent(match[1]) : '';
}

function normalizePath(pathname) {
  const normalized = pathname.replace(/\/+$/, '');
  return normalized || '/';
}

async function readJson(request) {
  try {
    const body = await request.json();
    return body && typeof body === 'object' ? body : {};
  } catch (_) {
    return {};
  }
}

async function readUpstreamJson(response) {
  const text = await response.text();
  if (!text) {
    return {};
  }

  try {
    return JSON.parse(text);
  } catch (_) {
    return { error: 'Suno returned non-JSON response', body: text };
  }
}

function isSunoError(upstream) {
  return typeof upstream.code === 'number' && upstream.code !== 200;
}

function normalizeSunoError(upstream, status) {
  const message =
    upstream?.data?.errorMessage ||
    upstream?.error?.message ||
    upstream?.msg ||
    upstream?.message ||
    upstream?.error ||
    `Suno request failed (${status})`;

  return {
    error: stringValue(message),
    status,
  };
}

function normalizeStatus(status) {
  switch (stringValue(status).trim().toUpperCase()) {
    case 'PENDING':
    case 'TEXT_SUCCESS':
    case '':
      return 'processing';
    case 'FIRST_SUCCESS':
      return 'first_success';
    case 'SUCCESS':
      return 'success';
    case 'COMPLETED':
      return 'completed';
    case 'CREATE_TASK_FAILED':
    case 'GENERATE_AUDIO_FAILED':
    case 'CALLBACK_EXCEPTION':
    case 'SENSITIVE_WORD_ERROR':
    case 'FAILED':
    case 'ERROR':
      return 'failed';
    default:
      return stringValue(status).trim().toLowerCase();
  }
}

function normalizeDate(value) {
  if (!value) {
    return null;
  }

  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed.toISOString();
}

function readTags(value) {
  if (Array.isArray(value)) {
    return value.map((item) => stringValue(item).trim()).filter(Boolean);
  }

  return stringValue(value)
    .split(/[,;\n]/)
    .map((item) => item.trim())
    .filter(Boolean);
}

function firstString(values) {
  for (const value of values) {
    const text = stringValue(value).trim();
    if (text) {
      return text;
    }
  }

  return '';
}

function stringValue(value) {
  if (value === null || value === undefined) {
    return '';
  }

  return String(value);
}

function numberValue(value, fallback) {
  const number = Number(value);
  return Number.isFinite(number) ? number : fallback;
}

function sunoBaseUrl(env) {
  return stringValue(env.SUNO_API_BASE_URL || DEFAULT_SUNO_BASE_URL).replace(/\/+$/, '');
}

function sunoHeaders(env) {
  return {
    Authorization: `Bearer ${env.SUNO_API_KEY}`,
    'Content-Type': 'application/json',
  };
}

function buildCorsHeaders(env) {
  return {
    'Access-Control-Allow-Origin': env.CORS_ORIGIN || '*',
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400',
  };
}

function jsonResponse(body, status, corsHeaders) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json; charset=utf-8',
    },
  });
}
