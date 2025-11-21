// lib/models/item_preview_sample.dart
import 'preview_response.dart';

/// 디버그용 샘플 PreviewResponse
PreviewResponse buildSamplePreviewResponse() {
  // 새 PreviewResponse 구조에 맞춘 샘플 JSON
  final sampleJson = {
    "state": "complete",
    "resolved": {
      "label": "헤어 스프레이",
      "canonical": "aerosol",
      "locale": "ko-KR"
    },
    "engine": {
      "req_id": "sample-req-id",
      "canonical": "aerosol",
      "decision": {
        "carry_on": {
          // 헤어 스프레이 기내는 금지라는 설정
          "status": "deny",
          "badges": [],
          "reason_codes": []
        },
        "checked": {
          // 위탁은 조건부 허용
          "status": "conditional_allow",
          "badges": [],
          "reason_codes": []
        }
      },
      "conditions": {
        "carry_on": {},
        "checked": {},
        "common": {}
      },
      "sources": [],
      "trace": [],
      "ai_tips": [
        {
          "id": "tip.split_100ml",
          "text": "100ml 이하 빈 용기에 소분하면 기내로 가져갈 수 있어요.",
          "tags": ["액체류", "기내"],
          "relevance": 0.95
        },
        {
          "id": "tip.zip_bag",
          "text": "액체는 1L 투명 지퍼백에 따로 넣어 보안대에서 한 번에 꺼낼 수 있게 하세요.",
          "tags": ["보안절차"],
          "relevance": 0.9
        }
      ]
    },
    "narration": {
      "title": "헤어 스프레이 · 350ml",
      "carry_on_card": {
        "status_label": "금지",
        "short_reason": "규정상 허용되지 않습니다."
      },
      "checked_card": {
        "status_label": "조건부 허용",
        "short_reason": "용기 500ml 이하, 총 2L, 압력캡 필요"
      },
      "bullets": [
        "보안: 100ml 이하만, 1L 지퍼백 1개 필요",
        "에어로졸: 용기 500ml 이하, 총 2000ml 한도",
        "기내 한도: 10kg · 115cm · 1pc"
      ],
      "badges": [
        "100ml",
        "10kg",
        "115cm",
        "1L zip bag",
        "1pc",
        "2L total",
        "500ml",
        "Pressure cap"
      ],
      "footnote": "세관/검역 규정은 별도 적용될 수 있습니다.",
      "sources": ["보안/KR", "보안/CN", "항공사/KE"]
    },
    "ai_tips": [
      {
        "id": "tip.split_100ml",
        "text": "100ml 이하 빈 용기에 소분하면 기내로 가져갈 수 있어요.",
        "tags": ["액체류", "기내"],
        "relevance": 0.95
      },
      {
        "id": "tip.zip_bag",
        "text": "액체는 1L 투명 지퍼백에 따로 넣어 보안대에서 한 번에 꺼낼 수 있게 하세요.",
        "tags": ["보안절차"],
        "relevance": 0.9
      }
    ],
    "flags": {
      "low_confidence": 0,
      "benign_category": "benign_general",
      "llm_needs_review": false,
      "missing_params": [],
      "needs_review": false
    }
  };

  return PreviewResponse.fromJson(sampleJson);
}
