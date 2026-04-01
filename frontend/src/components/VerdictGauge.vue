<template>
  <div class="verdict-gauge">
    <div class="gauge-header">
      <span class="gauge-title">判决结果预测</span>
      <span class="confidence-badge" :class="`conf-${confidenceLevel}`">
        置信度：{{ confidenceText }}
      </span>
    </div>

    <!-- 双向进度条 -->
    <div class="gauge-bar-container">
      <!-- 原告一侧（左） -->
      <div class="side plaintiff-side">
        <div class="side-label">{{ plaintiffLabel }}</div>
        <div class="side-pct">{{ (plaintiffProbability * 100).toFixed(0) }}%</div>
      </div>

      <!-- 进度条主体 -->
      <div class="bar-track">
        <div
          class="bar-fill plaintiff-fill"
          :style="{ width: `${plaintiffProbability * 100}%` }"
        />
        <div class="bar-center-line" />
        <div class="bar-fill defendant-fill" />
      </div>

      <!-- 被告一侧（右） -->
      <div class="side defendant-side">
        <div class="side-pct">{{ ((1 - plaintiffProbability) * 100).toFixed(0) }}%</div>
        <div class="side-label">{{ defendantLabel }}</div>
      </div>
    </div>

    <!-- 关键因素 -->
    <div v-if="keyFactors && keyFactors.length" class="key-factors">
      <div class="factors-title">核心决定因素</div>
      <ul class="factors-list">
        <li v-for="(factor, i) in keyFactors" :key="i" class="factor-item">
          <span class="factor-dot">◆</span>
          <span>{{ factor }}</span>
        </li>
      </ul>
    </div>

    <!-- 赔偿区间 -->
    <div v-if="compensationRange" class="compensation-info">
      <span class="comp-label">预计赔偿区间：</span>
      <span class="comp-value">
        {{ formatAmount(compensationRange.min) }} ～ {{ formatAmount(compensationRange.max) }}
        <span class="comp-currency">{{ compensationRange.currency || 'CNY' }}</span>
      </span>
      <span v-if="compensationRange.note" class="comp-note">（{{ compensationRange.note }}）</span>
    </div>

    <!-- 法律风险 -->
    <div v-if="legalRisks && legalRisks.length" class="legal-risks">
      <div class="risks-title">法律风险提示</div>
      <ul class="risks-list">
        <li v-for="(risk, i) in legalRisks" :key="i" class="risk-item">
          <span class="risk-icon">⚠</span>
          <span>{{ risk }}</span>
        </li>
      </ul>
    </div>

    <!-- 免责声明 -->
    <div class="disclaimer">
      ⚠ 本预测结果基于 AI 多智能体庭审模拟生成，仅供学术研究与教学参考，不代表真实司法判决，不构成任何法律建议。
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  // 原告/公诉方胜诉概率（0-1）
  plaintiffProbability: {
    type: Number,
    default: 0.5,
  },
  plaintiffLabel: {
    type: String,
    default: '原告胜诉',
  },
  defendantLabel: {
    type: String,
    default: '被告胜诉',
  },
  keyFactors: {
    type: Array,
    default: () => [],
  },
  compensationRange: {
    type: Object,
    default: null,
  },
  legalRisks: {
    type: Array,
    default: () => [],
  },
  // 'high' | 'medium' | 'low'
  confidenceLevel: {
    type: String,
    default: 'medium',
  },
})

const confidenceText = computed(() => ({
  high: '高',
  medium: '中',
  low: '低',
}[props.confidenceLevel] || '中'))

function formatAmount(val) {
  if (!val && val !== 0) return '—'
  return Number(val).toLocaleString('zh-CN')
}
</script>

<style scoped>
.verdict-gauge {
  background: #0f1923;
  border: 1px solid #1e3a5f;
  border-radius: 12px;
  padding: 20px;
}

.gauge-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}
.gauge-title {
  font-size: 15px;
  font-weight: 600;
  color: #e2e8f0;
}
.confidence-badge {
  font-size: 11px;
  padding: 2px 8px;
  border-radius: 10px;
  border: 1px solid;
}
.conf-high   { color: #4ade80; border-color: #4ade80; background: rgba(74,222,128,.1); }
.conf-medium { color: #f59e0b; border-color: #f59e0b; background: rgba(245,158,11,.1); }
.conf-low    { color: #f87171; border-color: #f87171; background: rgba(248,113,113,.1); }

/* 进度条区域 */
.gauge-bar-container {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 20px;
}

.side {
  display: flex;
  flex-direction: column;
  align-items: center;
  min-width: 56px;
}
.plaintiff-side { align-items: flex-start; }
.defendant-side { align-items: flex-end; }

.side-label {
  font-size: 11px;
  color: #94a3b8;
  white-space: nowrap;
}
.side-pct {
  font-size: 18px;
  font-weight: 700;
  font-variant-numeric: tabular-nums;
}
.plaintiff-side .side-pct { color: #3b82f6; }
.defendant-side .side-pct { color: #ef4444; }

/* 进度条主体 */
.bar-track {
  flex: 1;
  height: 14px;
  background: #1e293b;
  border-radius: 7px;
  position: relative;
  overflow: hidden;
}
.bar-fill {
  position: absolute;
  top: 0;
  height: 100%;
  transition: width 0.8s cubic-bezier(0.4, 0, 0.2, 1);
}
.plaintiff-fill {
  left: 0;
  background: linear-gradient(90deg, #1d4ed8, #3b82f6);
  border-radius: 7px 0 0 7px;
}
.defendant-fill {
  right: 0;
  background: linear-gradient(270deg, #b91c1c, #ef4444);
  border-radius: 0 7px 7px 0;
  width: v-bind("((1 - plaintiffProbability) * 100) + '%'");
}
.bar-center-line {
  position: absolute;
  left: 50%;
  top: 0;
  width: 2px;
  height: 100%;
  background: #334155;
  transform: translateX(-50%);
  z-index: 1;
}

/* 关键因素 */
.key-factors, .legal-risks {
  margin-top: 14px;
  padding-top: 14px;
  border-top: 1px solid #1e3a5f;
}
.factors-title, .risks-title {
  font-size: 12px;
  color: #64748b;
  margin-bottom: 8px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
.factors-list, .risks-list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 5px;
}
.factor-item, .risk-item {
  display: flex;
  gap: 8px;
  align-items: flex-start;
  font-size: 13px;
  color: #94a3b8;
}
.factor-dot { color: #3b82f6; font-size: 8px; padding-top: 4px; flex-shrink: 0; }
.risk-icon  { color: #f59e0b; font-size: 11px; padding-top: 2px; flex-shrink: 0; }

/* 赔偿区间 */
.compensation-info {
  margin-top: 12px;
  font-size: 13px;
  color: #94a3b8;
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  align-items: baseline;
}
.comp-label { color: #64748b; }
.comp-value { color: #e2e8f0; font-weight: 600; }
.comp-currency { font-size: 11px; color: #64748b; margin-left: 2px; }
.comp-note { font-size: 11px; color: #64748b; }

/* 免责声明 */
.disclaimer {
  margin-top: 16px;
  padding: 8px 12px;
  background: rgba(245, 158, 11, 0.06);
  border: 1px solid rgba(245, 158, 11, 0.2);
  border-radius: 6px;
  font-size: 11px;
  color: #78716c;
  line-height: 1.5;
}
</style>
