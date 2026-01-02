import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    chartData: Array,
    dateStart: String,
    dateEnd: String,
    maxPosts: Number,
    chartId: String
  }

  static GITHUB_COLORS = ['#ebedf0', '#9be9a8', '#40c463', '#30a14e', '#216e39']

  connect() {
    this.initChart()
    window.addEventListener('resize', this.handleResize.bind(this))
  }

  disconnect() {
    if (this.chart) {
      this.chart.dispose()
    }
    window.removeEventListener('resize', this.handleResize.bind(this))
  }

  initChart() {
    if (typeof echarts === 'undefined') {
      console.error('ECharts is not loaded')
      return
    }

    // 既存のチャートインスタンスを破棄
    const existingChart = echarts.getInstanceByDom(this.element)
    if (existingChart) {
      existingChart.dispose()
    }

    this.chart = echarts.init(this.element)

    const option = {
      title: {
        text: 'ヒートマップ',
        left: 'center',
        textStyle: {
          fontSize: 16,
          fontWeight: 'normal'
        }
      },
      tooltip: {
        formatter: (params) => {
          return `${params.data[0]}<br/>コミット数: ${params.data[1]}`
        }
      },
      visualMap: {
        show: false,
        min: 0,
        max: this.maxPostsValue > 0 ? this.maxPostsValue : 1,
        type: 'piecewise',
        pieces: this.buildColorPieces()
      },
      calendar: {
        top: 60,
        left: 'center',
        cellSize: 20,
        range: [this.dateStartValue, this.dateEndValue],
        itemStyle: {
          borderColor: '#fff',
          color: '#f5f5f5',
          borderWidth: 2,
          borderRadius: 4
        },
        splitLine: {
          lineStyle: {
            color: 'rgba(0, 0, 0, 0)',
            width: 1
          }
        },
        yearLabel: { show: false }
      },
      series: {
        type: 'heatmap',
        coordinateSystem: 'calendar',
        data: this.chartDataValue
      }
    }

    this.chart.setOption(option)
  }

  buildColorPieces() {
    const colors = this.constructor.GITHUB_COLORS
    return [
      { value: 0, color: colors[0] },
      { min: 1, max: 2, color: colors[1] },
      { min: 3, max: 4, color: colors[2] },
      { min: 5, max: 6, color: colors[3] },
      { min: 7, color: colors[4] }
    ]
  }

  handleResize() {
    if (this.chart) {
      this.chart.resize()
    }
  }
}
