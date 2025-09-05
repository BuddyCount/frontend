import 'package:flutter/material.dart';
import 'dart:math';
import '../models/group.dart';
import '../models/expense.dart';
import '../models/person.dart';
import '../services/api_service.dart';

class ExpenseAnalyticsWidget extends StatefulWidget {
  final Group group;
  
  const ExpenseAnalyticsWidget({
    super.key,
    required this.group,
  });

  @override
  State<ExpenseAnalyticsWidget> createState() => _ExpenseAnalyticsWidgetState();
}

class _ExpenseAnalyticsWidgetState extends State<ExpenseAnalyticsWidget> {
  Person? _selectedMember;
  String _selectedTimeRange = '30d'; // 7d, 30d, 90d, 1y, all
  bool _showCumulative = false;
  
  // Prediction-related state
  bool _showPredictions = false;
  DateTime _predictionStartDate = DateTime.now().subtract(const Duration(days: 30));
  int _predictionLength = 7;
  List<double> _predictions = [];
  bool _isLoadingPredictions = false;

  @override
  Widget build(BuildContext context) {
    final filteredExpenses = _getFilteredExpenses();
    final chartData = _prepareChartData(filteredExpenses);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and filters
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Expense Analytics',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _showPredictions ? Icons.visibility_off : Icons.trending_up,
                    color: _showPredictions ? Colors.blue : null,
                  ),
                  onPressed: _togglePredictions,
                  tooltip: _showPredictions ? 'Hide Predictions' : 'Show Predictions',
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterDialog,
                  tooltip: 'Filter Options',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Filter summary
            _buildFilterSummary(),
            const SizedBox(height: 16),
            
            // Prediction controls
            if (_showPredictions) _buildPredictionControls(),
            
            // Chart
            if (chartData.isNotEmpty) ...[
              Text(
                _showCumulative ? 'Cumulative Expenses Over Time' : 'Daily Expenses Over Time',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200, // Chart height
                child: _buildExpenseChart(chartData),
              ),
              const SizedBox(height: 16),
            ],
            
            // Statistics
            _buildStatistics(filteredExpenses),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSummary() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Time range filter
        FilterChip(
          label: Text(_getTimeRangeLabel()),
          selected: true,
          onSelected: (_) => _showFilterDialog(),
          avatar: const Icon(Icons.schedule, size: 16),
        ),
        
        // Member filter
        if (_selectedMember != null)
          FilterChip(
            label: Text('${_selectedMember!.name} only'),
            selected: true,
            onSelected: (_) => setState(() => _selectedMember = null),
            avatar: const Icon(Icons.person, size: 16),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () => setState(() => _selectedMember = null),
          ),
        
        // Cumulative toggle
        FilterChip(
          label: Text(_showCumulative ? 'Cumulative' : 'Daily'),
          selected: _showCumulative,
          onSelected: (selected) => setState(() => _showCumulative = selected),
          avatar: Icon(
            _showCumulative ? Icons.trending_up : Icons.bar_chart,
            size: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionControls() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Prediction Settings',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
              const Spacer(),
              if (_isLoadingPredictions)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Date',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: _selectPredictionStartDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Text(
                              '${_predictionStartDate.day}/${_predictionStartDate.month}/${_predictionStartDate.year}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prediction Length (days)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<int>(
                      value: _predictionLength,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [3, 5, 7, 10, 14, 21, 30].map((days) {
                        return DropdownMenuItem(
                          value: days,
                          child: Text('$days days'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _predictionLength = value;
                          });
                          _updatePredictionSettings();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_predictions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Predicted ${_predictions.length} days ahead',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpenseChart(List<ChartDataPoint> chartData) {
    if (chartData.isEmpty) {
      return const Center(
        child: Text('No data to display'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartHeight = constraints.maxHeight - 40; // Reserve 40px for X-axis labels
        
        return Column(
          children: [
            // Chart area
            SizedBox(
              height: chartHeight > 0 ? chartHeight : 160, // Fallback height
              child: CustomPaint(
                painter: ExpenseChartPainter(
                  chartData: chartData,
                  showCumulative: _showCumulative,
                  context: context,
                ),
                size: Size.infinite,
              ),
            ),
            // X-axis labels (dates)
            SizedBox(
              height: 40,
              child: _buildXAxisLabels(chartData),
            ),
          ],
        );
      },
    );
  }

  Widget _buildXAxisLabels(List<ChartDataPoint> chartData) {
    if (chartData.length <= 1) return const SizedBox.shrink();
    
    // Show max 5 date labels to avoid overcrowding
    final step = (chartData.length - 1) / 4;
    final labels = <Widget>[];
    
    for (int i = 0; i <= 4; i++) {
      final index = (i * step).round();
      if (index < chartData.length) {
        final date = chartData[index].date;
        labels.add(
          Expanded(
            child: Center(
              child: Text(
                _formatDateLabel(date),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }
    }
    
    return Row(children: labels);
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      // Show day name for recent dates
      return _getDayName(date.weekday);
    } else {
      // Show date for older dates
      return '${date.month}/${date.day}';
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }

  Widget _buildStatistics(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return const Center(
        child: Text('No expenses in selected period'),
      );
    }

    final totalAmount = expenses.fold(0.0, (sum, expense) => sum + expense.amount);
    final averagePerDay = _calculateAveragePerDay(expenses);
    final highestExpense = expenses.reduce((a, b) => a.amount > b.amount ? a : b);
    final lowestExpense = expenses.reduce((a, b) => a.amount < b.amount ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total',
                '\$${totalAmount.toStringAsFixed(2)}',
                Icons.account_balance_wallet,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Daily Avg',
                '\$${averagePerDay.toStringAsFixed(2)}',
                Icons.trending_up,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Highest',
                '\$${highestExpense.amount.toStringAsFixed(2)}',
                Icons.arrow_upward,
                Colors.red,
                subtitle: highestExpense.name,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Lowest',
                '\$${lowestExpense.amount.toStringAsFixed(2)}',
                Icons.arrow_downward,
                Colors.orange,
                subtitle: lowestExpense.name,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Time range selection
            ListTile(
              title: const Text('Time Range'),
              subtitle: Text(_getTimeRangeLabel()),
              trailing: DropdownButton<String>(
                value: _selectedTimeRange,
                items: const [
                  DropdownMenuItem(value: '7d', child: Text('Last 7 days')),
                  DropdownMenuItem(value: '30d', child: Text('Last 30 days')),
                  DropdownMenuItem(value: '90d', child: Text('Last 90 days')),
                  DropdownMenuItem(value: '1y', child: Text('Last year')),
                  DropdownMenuItem(value: 'all', child: Text('All time')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedTimeRange = value);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
            
            // Member selection
            ListTile(
              title: const Text('Filter by Member'),
              subtitle: Text(_selectedMember?.name ?? 'All members'),
              trailing: DropdownButton<Person?>(
                value: _selectedMember,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All members'),
                  ),
                  ...widget.group.members.map((member) => 
                    DropdownMenuItem(
                      value: member,
                      child: Text(member.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedMember = value);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<Expense> _getFilteredExpenses() {
    List<Expense> expenses = List.from(widget.group.expenses);
    
    // Filter by member if selected
    if (_selectedMember != null) {
      expenses = expenses.where((expense) => 
        expense.paidBy == _selectedMember!.id ||
        (expense.customPaidBy != null && expense.customPaidBy!.containsKey(_selectedMember!.id)) ||
        expense.splitBetween.contains(_selectedMember!.name)
      ).toList();
    }
    
    // Filter by time range
    final now = DateTime.now();
    final cutoffDate = _getCutoffDate(now);
    
    if (cutoffDate != null) {
      expenses = expenses.where((expense) => 
        expense.date.isAfter(cutoffDate)
      ).toList();
    }
    
    // Sort by date
    expenses.sort((a, b) => a.date.compareTo(b.date));
    
    return expenses;
  }

  DateTime? _getCutoffDate(DateTime now) {
    switch (_selectedTimeRange) {
      case '7d':
        return now.subtract(const Duration(days: 7));
      case '30d':
        return now.subtract(const Duration(days: 30));
      case '90d':
        return now.subtract(const Duration(days: 90));
      case '1y':
        return DateTime(now.year - 1, now.month, now.day);
      case 'all':
      default:
        return null;
    }
  }

  String _getTimeRangeLabel() {
    switch (_selectedTimeRange) {
      case '7d':
        return 'Last 7 days';
      case '30d':
        return 'Last 30 days';
      case '90d':
        return 'Last 90 days';
      case '1y':
        return 'Last year';
      case 'all':
        return 'All time';
      default:
        return 'Last 30 days';
    }
  }

  List<ChartDataPoint> _prepareChartData(List<Expense> expenses) {
    final Map<DateTime, double> dailyTotals = {};
    
    // Group expenses by date
    for (final expense in expenses) {
      final date = DateTime(expense.date.year, expense.date.month, expense.date.day);
      dailyTotals[date] = (dailyTotals[date] ?? 0) + expense.amount;
    }
    
    // Add predictions if enabled
    if (_showPredictions && _predictions.isNotEmpty) {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      for (int i = 0; i < _predictions.length; i++) {
        final predictionDate = tomorrow.add(Duration(days: i));
        dailyTotals[predictionDate] = _predictions[i];
      }
    }
    
    // Convert to chart data points
    final sortedDates = dailyTotals.keys.toList()..sort();
    final List<ChartDataPoint> chartData = [];
    
    if (_showCumulative) {
      double cumulative = 0;
      for (final date in sortedDates) {
        cumulative += dailyTotals[date]!;
        chartData.add(ChartDataPoint(date, cumulative, isPrediction: _isPredictionDate(date)));
      }
    } else {
      for (final date in sortedDates) {
        chartData.add(ChartDataPoint(date, dailyTotals[date]!, isPrediction: _isPredictionDate(date)));
      }
    }
    
    return chartData;
  }
  
  bool _isPredictionDate(DateTime date) {
    if (!_showPredictions || _predictions.isEmpty) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final lastPredictionDate = tomorrow.add(Duration(days: _predictions.length - 1));
    return date.isAfter(DateTime.now()) && 
           (date.isAtSameMomentAs(tomorrow) || date.isBefore(lastPredictionDate) || date.isAtSameMomentAs(lastPredictionDate));
  }

  double _calculateAveragePerDay(List<Expense> expenses) {
    if (expenses.isEmpty) return 0;
    
    final totalAmount = expenses.fold(0.0, (sum, expense) => sum + expense.amount);
    final days = _getDaysInRange(expenses);
    
    return days > 0 ? totalAmount / days : 0;
  }

  int _getDaysInRange(List<Expense> expenses) {
    if (expenses.isEmpty) return 0;
    
    final sortedExpenses = List<Expense>.from(expenses)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    final firstDate = sortedExpenses.first.date;
    final lastDate = sortedExpenses.last.date;
    
    return lastDate.difference(firstDate).inDays + 1;
  }

  Future<void> _fetchPredictions() async {
    if (_isLoadingPredictions) return;
    
    setState(() {
      _isLoadingPredictions = true;
    });
    
    try {
      final predictions = await ApiService.getExpensePredictions(
        groupId: widget.group.id,
        startDate: _predictionStartDate,
        predictionLength: _predictionLength,
      );
      
      setState(() {
        _predictions = predictions;
        _isLoadingPredictions = false;
      });
      
      print('✅ Successfully loaded ${predictions.length} predictions');
    } catch (e) {
      setState(() {
        _isLoadingPredictions = false;
      });
      
      print('❌ Error fetching predictions: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load predictions: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  void _togglePredictions() {
    setState(() {
      _showPredictions = !_showPredictions;
    });
    
    if (_showPredictions && _predictions.isEmpty) {
      _fetchPredictions();
    }
  }
  
  void _updatePredictionSettings() {
    setState(() {
      _predictions.clear(); // Clear old predictions
    });
    
    if (_showPredictions) {
      _fetchPredictions();
    }
  }
  
  Future<void> _selectPredictionStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _predictionStartDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _predictionStartDate) {
      setState(() {
        _predictionStartDate = picked;
      });
      _updatePredictionSettings();
    }
  }
}

class ChartDataPoint {
  final DateTime date;
  final double value;
  final bool isPrediction;
  
  ChartDataPoint(this.date, this.value, {this.isPrediction = false});
}

class ExpenseChartPainter extends CustomPainter {
  final List<ChartDataPoint> chartData;
  final bool showCumulative;
  final BuildContext context;
  
  ExpenseChartPainter({
    required this.chartData,
    required this.showCumulative,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (chartData.isEmpty) return;

    final paint = Paint()
      ..color = Theme.of(context).primaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Theme.of(context).primaryColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final predictionFillPaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );

    final width = size.width;
    final height = size.height;
    
    final minValue = chartData.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final maxValue = chartData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final valueRange = maxValue - minValue;
    
    // Safety check for zero range
    if (valueRange == 0) return;
    
    final minDate = chartData.first.date;
    final maxDate = chartData.last.date;
    final dateRange = maxDate.difference(minDate).inMilliseconds;
    
    // Safety check for zero date range
    if (dateRange == 0) return;

    // Calculate Y-axis labels
    final yLabels = _calculateYLabels(minValue, maxValue);
    final yLabelWidth = 40.0; // Reduced space for Y-axis labels
    final chartWidth = width - yLabelWidth;
    final chartHeight = height;
    
    // Draw Y-axis grid lines and labels
    for (final label in yLabels) {
      final y = chartHeight - ((label - minValue) / valueRange) * chartHeight;
      
      // Skip if y is NaN or invalid
      if (y.isNaN || y.isInfinite || y < 0 || y > chartHeight) continue;
      
      // Grid line
      canvas.drawLine(
        Offset(yLabelWidth, y),
        Offset(width, y),
        gridPaint,
      );
      
      // Y-axis label
      textPainter.text = TextSpan(
        text: '\$${label.toStringAsFixed(0)}',
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey.shade600,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(yLabelWidth - textPainter.width - 8, y - textPainter.height / 2),
      );
    }

    // Separate historical data from predictions
    final historicalData = <ChartDataPoint>[];
    final predictionData = <ChartDataPoint>[];
    
    for (final point in chartData) {
      if (point.isPrediction) {
        predictionData.add(point);
      } else {
        historicalData.add(point);
      }
    }
    
    // Draw historical data
    if (historicalData.isNotEmpty) {
      final histPath = Path();
      final histFillPath = Path();
      
      for (int i = 0; i < historicalData.length; i++) {
        final point = historicalData[i];
        final x = yLabelWidth + (point.date.difference(minDate).inMilliseconds / dateRange) * chartWidth;
        final y = chartHeight - ((point.value - minValue) / valueRange) * chartHeight;
        
        if (x.isNaN || x.isInfinite || y.isNaN || y.isInfinite) continue;
        
        if (i == 0) {
          histPath.moveTo(x, y);
          histFillPath.moveTo(x, chartHeight);
          histFillPath.lineTo(x, y);
        } else {
          histPath.lineTo(x, y);
          histFillPath.lineTo(x, y);
        }
      }
      
      // Complete the fill path
      histFillPath.lineTo(width, chartHeight);
      histFillPath.close();
      
      // Draw historical data
      canvas.drawPath(histFillPath, fillPaint);
      canvas.drawPath(histPath, paint);
    }
    
    // Draw predictions
    if (predictionData.isNotEmpty) {
      final predPath = Path();
      final predFillPath = Path();
      
      for (int i = 0; i < predictionData.length; i++) {
        final point = predictionData[i];
        final x = yLabelWidth + (point.date.difference(minDate).inMilliseconds / dateRange) * chartWidth;
        final y = chartHeight - ((point.value - minValue) / valueRange) * chartHeight;
        
        if (x.isNaN || x.isInfinite || y.isNaN || y.isInfinite) continue;
        
        if (i == 0) {
          predPath.moveTo(x, y);
          predFillPath.moveTo(x, chartHeight);
          predFillPath.lineTo(x, y);
        } else {
          predPath.lineTo(x, y);
          predFillPath.lineTo(x, y);
        }
      }
      
      // Complete the fill path
      predFillPath.lineTo(width, chartHeight);
      predFillPath.close();
      
      // Draw predictions with dashed line
      final dashPaint = Paint()
        ..color = Colors.orange
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      
      canvas.drawPath(predFillPath, predictionFillPaint);
      canvas.drawPath(predPath, dashPaint);
    }

    // Draw data points
    final pointPaint = Paint()
      ..color = Theme.of(context).primaryColor
      ..style = PaintingStyle.fill;

    final predictionPointPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;

    for (final point in chartData) {
      final x = yLabelWidth + (point.date.difference(minDate).inMilliseconds / dateRange) * chartWidth;
      final y = chartHeight - ((point.value - minValue) / valueRange) * chartHeight;
      
      // Skip if coordinates are NaN or invalid
      if (x.isNaN || x.isInfinite || y.isNaN || y.isInfinite) continue;
      
      // Use different colors for predictions
      final pointPaintToUse = point.isPrediction ? predictionPointPaint : pointPaint;
      canvas.drawCircle(Offset(x, y), 3, pointPaintToUse);
    }

    // Draw Y-axis line
    canvas.drawLine(
      Offset(yLabelWidth, 0),
      Offset(yLabelWidth, chartHeight),
      gridPaint,
    );
  }

  List<double> _calculateYLabels(double minValue, double maxValue) {
    final range = maxValue - minValue;
    if (range == 0) return [minValue];
    
    // Calculate nice round numbers for Y-axis labels (max 3 labels)
    final step = range / 2;
    final niceStep = _getNiceStep(step);
    
    final labels = <double>[];
    final start = (minValue / niceStep).floor() * niceStep;
    final end = (maxValue / niceStep).ceil() * niceStep;
    
    for (double value = start; value <= end; value += niceStep) {
      if (value >= minValue && value <= maxValue && labels.length < 3) {
        labels.add(value);
      }
    }
    
    return labels;
  }

  double _getNiceStep(double step) {
    final magnitude = pow(10, (log(step) / ln10).floor()).toDouble();
    final normalized = step / magnitude;
    
    if (normalized < 1.5) return magnitude;
    if (normalized < 3) return 2 * magnitude;
    if (normalized < 7) return 5 * magnitude;
    return 10 * magnitude;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}