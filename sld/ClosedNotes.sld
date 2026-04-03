<?xml version="1.0" encoding="UTF-8"?>
<!--
SLD file with green color scale for closed OSM notes.
Colors and transparency based on years_since_closed (vetustez).
Different shapes based on country_shape_mod (id_country % 6): 0 triangle, 1 circle,
2 square, 3 star, 4 shape://carrow, 5 arrow. International waters: -1.

Color scale (inverted - old = white with transparency, recent = bright green):
- 0 years: Bright green (#00FF00), opacity 1.0
- 1-2 years: Light green (#80FF80), opacity 0.9
- 3-4 years: Very light green (#B0FFB0), opacity 0.7
- 5-6 years: Almost white green (#D0FFD0), opacity 0.5
- 7-8 years: Very almost white green (#E8FFE8), opacity 0.3
- 9+ years: White (#FFFFFF), opacity 0.2

Author: Andres Gomez (AngocA)
Version: 2025-12-30
-->
<StyledLayerDescriptor xmlns="http://www.opengis.net/sld" xmlns:se="http://www.opengis.net/se" xmlns:ogc="http://www.opengis.net/ogc" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xlink="http://www.w3.org/1999/xlink" xsi:schemaLocation="http://www.opengis.net/sld http://schemas.opengis.net/sld/1.1.0/StyledLayerDescriptor.xsd" version="1.1.0">
  <NamedLayer>
    <se:Name>notes closed</se:Name>
    <UserStyle>
      <se:Name>notes closed</se:Name>
      <se:FeatureTypeStyle>
        <!-- Very recent (0 years): Bright green, full opacity -->
        <!-- Shape -1: Circle -->
        <se:Rule>
          <se:Name>0 years - International Waters - Dark Green</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>-1</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>0</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>1</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>circle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#00FF00</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">1.0</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">1.0</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 0: Triangle -->
        <se:Rule>
          <se:Name>0 years - Shape 0 - Bright Green Triangle</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>0</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>0</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>1</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>triangle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#00FF00</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">1.0</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">1.0</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 1: Circle -->
        <se:Rule>
          <se:Name>0 years - Shape 1 - Bright Green Circle</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>1</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>0</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>1</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>circle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#00FF00</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">1.0</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">1.0</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 2: Square -->
        <se:Rule>
          <se:Name>0 years - Shape 2 - Bright Green Square</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>2</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>0</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>1</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>square</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#00FF00</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">1.0</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">1.0</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 3: Star -->
        <se:Rule>
          <se:Name>0 years - Shape 3 - Bright Green Star</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>3</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>0</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>1</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>star</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#00FF00</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">1.0</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">1.0</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 4: closed arrow (shape://carrow) -->
        <se:Rule>
          <se:Name>0 years - Shape 4 - Bright Green closed arrow</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>4</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>0</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>1</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>shape://carrow</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#00FF00</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">1.0</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">1.0</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 5: Arrow -->
        <se:Rule>
          <se:Name>0 years - Shape 5 - Bright Green Arrow</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>5</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>0</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>1</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>arrow</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#00FF00</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">1.0</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">1.0</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 6: Plus -->
        <!-- Shape 7: Times -->
        <!-- Shape 8: Dot -->
        <!-- Shape 9: Open Arrow -->
        <!-- Shape 10: Closed Arrow -->
        <!-- Shape 11: Slash -->
        <!-- Shape 6: Plus -->
        <!-- Shape 7: Times -->
        <!-- Shape 8: Dot -->
        <!-- Shape 9: Open Arrow -->
        <!-- Shape 10: Closed Arrow -->
        <!-- Shape 11: Slash -->
        <!-- 1-2 years: Medium green, opacity 0.9 -->
        <!-- Shape -1: Circle -->
        <se:Rule>
          <se:Name>1-2 years - International Waters - Medium Green</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>-1</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>1</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>3</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>circle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#80FF80</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.9</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.9</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 0: Triangle -->
        <se:Rule>
          <se:Name>1-2 years - Shape 0 - Medium Green Triangle</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>0</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>1</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>3</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>triangle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#80FF80</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.9</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.9</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 1: Circle -->
        <se:Rule>
          <se:Name>1-2 years - Shape 1 - Medium Green Circle</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>1</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>1</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>3</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>circle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#80FF80</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.9</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.9</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 2: Square -->
        <se:Rule>
          <se:Name>1-2 years - Shape 2 - Medium Green Square</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>2</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>1</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>3</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>square</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#80FF80</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.9</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.9</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 3: Star -->
        <se:Rule>
          <se:Name>1-2 years - Shape 3 - Medium Green Star</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>3</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>1</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>3</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>star</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#80FF80</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.9</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.9</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 4: closed arrow (shape://carrow) -->
        <se:Rule>
          <se:Name>1-2 years - Shape 4 - Medium Green closed arrow</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>4</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>1</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>3</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>shape://carrow</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#80FF80</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.9</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.9</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 5: Arrow -->
        <se:Rule>
          <se:Name>1-2 years - Shape 5 - Medium Green Arrow</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>5</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>1</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>3</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>arrow</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#80FF80</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.9</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.9</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- 3-4 years: Medium-light green, opacity 0.7 -->
        <!-- Shape -1: Circle -->
        <se:Rule>
          <se:Name>3-4 years - International Waters - Medium-Light Green</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>-1</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>3</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>5</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>circle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#B0FFB0</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.7</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.7</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 6: Plus -->
        <!-- Shape 7: Times -->
        <!-- Shape 8: Dot -->
        <!-- Shape 9: Open Arrow -->
        <!-- Shape 10: Closed Arrow -->
        <!-- Shape 11: Slash -->
        <!-- Shape 0: Triangle -->
        <se:Rule>
          <se:Name>3-4 years - Shape 0 - Medium-Light Green Triangle</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>0</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>3</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>5</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>triangle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#B0FFB0</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.7</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.7</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 1: Circle -->
        <se:Rule>
          <se:Name>3-4 years - Shape 1 - Medium-Light Green Circle</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>1</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>3</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>5</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>circle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#B0FFB0</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.7</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.7</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 2: Square -->
        <se:Rule>
          <se:Name>3-4 years - Shape 2 - Medium-Light Green Square</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>2</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>3</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>5</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>square</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#B0FFB0</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.7</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.7</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 3: Star -->
        <se:Rule>
          <se:Name>3-4 years - Shape 3 - Medium-Light Green Star</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>3</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>3</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>5</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>star</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#B0FFB0</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.7</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.7</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 4: closed arrow (shape://carrow) -->
        <se:Rule>
          <se:Name>3-4 years - Shape 4 - Medium-Light Green closed arrow</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>4</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>3</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>5</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>shape://carrow</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#B0FFB0</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.7</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.7</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 5: Arrow -->
        <se:Rule>
          <se:Name>3-4 years - Shape 5 - Medium-Light Green Arrow</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>5</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>3</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>5</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>arrow</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#B0FFB0</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.7</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.7</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- 5-6 years: Light green, opacity 0.5 -->
        <!-- Shape -1: Circle -->
        <se:Rule>
          <se:Name>5-6 years - International Waters - Light Green</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>-1</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>5</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>7</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>circle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#D0FFD0</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.5</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.5</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 6: Plus -->
        <!-- Shape 7: Times -->
        <!-- Shape 8: Dot -->
        <!-- Shape 9: Open Arrow -->
        <!-- Shape 10: Closed Arrow -->
        <!-- Shape 11: Slash -->
        <!-- Shape 0: Triangle -->
        <se:Rule>
          <se:Name>5-6 years - Shape 0 - Light Green Triangle</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>0</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>5</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>7</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>triangle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#D0FFD0</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.5</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.5</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 1: Circle -->
        <se:Rule>
          <se:Name>5-6 years - Shape 1 - Light Green Circle</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>1</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>5</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>7</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>circle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#D0FFD0</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.5</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.5</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 2: Square -->
        <se:Rule>
          <se:Name>5-6 years - Shape 2 - Light Green Square</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>2</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>5</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>7</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>square</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#D0FFD0</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.5</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.5</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 3: Star -->
        <se:Rule>
          <se:Name>5-6 years - Shape 3 - Light Green Star</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>3</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>5</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>7</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>star</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#D0FFD0</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.5</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.5</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 4: closed arrow (shape://carrow) -->
        <se:Rule>
          <se:Name>5-6 years - Shape 4 - Light Green closed arrow</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>4</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>5</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>7</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>shape://carrow</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#D0FFD0</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.5</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.5</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 5: Arrow -->
        <se:Rule>
          <se:Name>5-6 years - Shape 5 - Light Green Arrow</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>5</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>5</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>7</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>arrow</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#D0FFD0</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.5</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.5</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- 7-8 years: Very light green, opacity 0.3 -->
        <!-- Shape -1: Circle -->
        <se:Rule>
          <se:Name>7-8 years - International Waters - Very Light Green</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>-1</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>7</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>9</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>circle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#E8FFE8</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.3</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.3</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 6: Plus -->
        <!-- Shape 7: Times -->
        <!-- Shape 8: Dot -->
        <!-- Shape 9: Open Arrow -->
        <!-- Shape 10: Closed Arrow -->
        <!-- Shape 11: Slash -->
        <!-- Shape 0: Triangle -->
        <se:Rule>
          <se:Name>7-8 years - Shape 0 - Very Light Green Triangle</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>0</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>7</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>9</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>triangle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#E8FFE8</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.3</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.3</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 1: Circle -->
        <se:Rule>
          <se:Name>7-8 years - Shape 1 - Very Light Green Circle</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>1</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>7</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>9</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>circle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#E8FFE8</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.3</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.3</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 2: Square -->
        <se:Rule>
          <se:Name>7-8 years - Shape 2 - Very Light Green Square</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>2</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>7</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>9</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>square</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#E8FFE8</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.3</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.3</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 3: Star -->
        <se:Rule>
          <se:Name>7-8 years - Shape 3 - Very Light Green Star</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>3</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>7</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>9</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>star</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#E8FFE8</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.3</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.3</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 4: closed arrow (shape://carrow) -->
        <se:Rule>
          <se:Name>7-8 years - Shape 4 - Very Light Green closed arrow</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>4</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>7</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>9</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>shape://carrow</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#E8FFE8</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.3</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.3</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 5: Arrow -->
        <se:Rule>
          <se:Name>7-8 years - Shape 5 - Very Light Green Arrow</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>5</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:And>
                <ogc:PropertyIsGreaterThanOrEqualTo>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>7</ogc:Literal>
                </ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyIsLessThan>
                  <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                  <ogc:Literal>9</ogc:Literal>
                </ogc:PropertyIsLessThan>
              </ogc:And>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>arrow</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#E8FFE8</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.3</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.3</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- 9+ years: Very dark green, opacity 0.2 -->
        <!-- Shape -1: Circle -->
        <se:Rule>
          <se:Name>9+ years - International Waters - Very Light Green</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>-1</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                <ogc:Literal>9</ogc:Literal>
              </ogc:PropertyIsGreaterThanOrEqualTo>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>circle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#FFFFFF</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.2</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.2</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 6: Plus -->
        <!-- Shape 7: Times -->
        <!-- Shape 8: Dot -->
        <!-- Shape 9: Open Arrow -->
        <!-- Shape 10: Closed Arrow -->
        <!-- Shape 11: Slash -->
        <!-- Shape 0: Triangle -->
        <se:Rule>
          <se:Name>9+ years - Shape 0 - Very Dark Green Triangle</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>0</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                <ogc:Literal>9</ogc:Literal>
              </ogc:PropertyIsGreaterThanOrEqualTo>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>triangle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#FFFFFF</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.2</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.2</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 1: Circle -->
        <se:Rule>
          <se:Name>9+ years - Shape 1 - Very Dark Green Circle</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>1</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                <ogc:Literal>9</ogc:Literal>
              </ogc:PropertyIsGreaterThanOrEqualTo>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>circle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#FFFFFF</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.2</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.2</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 2: Square -->
        <se:Rule>
          <se:Name>9+ years - Shape 2 - Very Dark Green Square</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>2</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                <ogc:Literal>9</ogc:Literal>
              </ogc:PropertyIsGreaterThanOrEqualTo>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>square</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#FFFFFF</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.2</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.2</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 3: Star -->
        <se:Rule>
          <se:Name>9+ years - Shape 3 - Very Dark Green Star</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>3</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                <ogc:Literal>9</ogc:Literal>
              </ogc:PropertyIsGreaterThanOrEqualTo>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>star</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#FFFFFF</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.2</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.2</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 4: closed arrow (shape://carrow) -->
        <se:Rule>
          <se:Name>9+ years - Shape 4 - Very Dark Green closed arrow</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>4</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                <ogc:Literal>9</ogc:Literal>
              </ogc:PropertyIsGreaterThanOrEqualTo>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>shape://carrow</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#FFFFFF</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.2</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.2</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Shape 5: Arrow -->
        <se:Rule>
          <se:Name>9+ years - Shape 5 - Very Dark Green Arrow</se:Name>
          <ogc:Filter>
            <ogc:And>
              <ogc:PropertyIsEqualTo>
                <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
                <ogc:Literal>5</ogc:Literal>
              </ogc:PropertyIsEqualTo>
              <ogc:PropertyIsGreaterThanOrEqualTo>
                <ogc:PropertyName>years_since_closed</ogc:PropertyName>
                <ogc:Literal>9</ogc:Literal>
              </ogc:PropertyIsGreaterThanOrEqualTo>
            </ogc:And>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>arrow</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#FFFFFF</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.2</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.2</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>14</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
        <!-- Default rule for NULL country_shape_mod (no country assigned) -->
        <se:Rule>
          <se:Name>Default - Gray Circle (No Country)</se:Name>
          <ogc:Filter>
            <ogc:PropertyIsNull>
              <ogc:PropertyName>country_shape_mod</ogc:PropertyName>
            </ogc:PropertyIsNull>
          </ogc:Filter>
          <se:PointSymbolizer>
            <se:Graphic>
              <se:Mark>
                <se:WellKnownName>circle</se:WellKnownName>
                <se:Fill>
                  <se:SvgParameter name="fill">#888888</se:SvgParameter>
                  <se:SvgParameter name="fill-opacity">0.5</se:SvgParameter>
                </se:Fill>
                <se:Stroke>
                  <se:SvgParameter name="stroke">#000000</se:SvgParameter>
                  <se:SvgParameter name="stroke-width">1</se:SvgParameter>
                  <se:SvgParameter name="stroke-opacity">0.5</se:SvgParameter>
                </se:Stroke>
              </se:Mark>
              <se:Size>12</se:Size>
            </se:Graphic>
          </se:PointSymbolizer>
        </se:Rule>
      </se:FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
